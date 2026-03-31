package main

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
)

const (
	lfsContentType = "application/vnd.git-lfs+json"
	urlExpiry      = 3600 // seconds
	secretCacheTTL = 5 * time.Minute
)

// LFS Batch API request structure
type BatchRequest struct {
	Operation string      `json:"operation"`
	Objects   []LFSObject `json:"objects"`
}

type LFSObject struct {
	OID  string `json:"oid"`
	Size int64  `json:"size"`
}

// LFS Batch API response structure
type BatchResponse struct {
	Transfer string            `json:"transfer"`
	Objects  []LFSObjectResult `json:"objects"`
}

type LFSObjectResult struct {
	OID     string               `json:"oid"`
	Size    int64                `json:"size"`
	Actions map[string]LFSAction `json:"actions,omitempty"`
	Error   *LFSObjectError      `json:"error,omitempty"`
}

type LFSAction struct {
	HREF      string            `json:"href"`
	ExpiresIn int               `json:"expires_in"`
	Header    map[string]string `json:"header,omitempty"`
}

type LFSObjectError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

// secretCache caches the API keys from Secrets Manager to avoid
// fetching on every request
type secretCache struct {
	mu        sync.RWMutex
	keys      map[string]string // curator name -> api key
	fetchedAt time.Time
}

func (c *secretCache) isExpired() bool {
	return time.Since(c.fetchedAt) > secretCacheTTL
}

var (
	s3Client    *s3.Client
	s3Presign   *s3.PresignClient
	smClient    *secretsmanager.Client
	bucketName  string
	secretName  string
	apiKeyCache = &secretCache{}
)

func init() {
	bucketName = os.Getenv("S3_BUCKET")
	if bucketName == "" {
		log.Fatal("S3_BUCKET environment variable is required")
	}

	secretName = os.Getenv("LFS_SECRET_NAME")
	if secretName == "" {
		log.Fatal("LFS_SECRET_NAME environment variable is required")
	}

	cfg, err := config.LoadDefaultConfig(context.Background())
	if err != nil {
		log.Fatalf("failed to load AWS config: %v", err)
	}

	s3Client = s3.NewFromConfig(cfg)
	s3Presign = s3.NewPresignClient(s3Client)
	smClient = secretsmanager.NewFromConfig(cfg)
}

// getAPIKeys fetches curator keys from Secrets Manager, using a cache
// to avoid fetching on every request. Cache expires every 5 minutes
// so key additions and revocations take effect promptly.
func getAPIKeys(ctx context.Context) (map[string]string, error) {
	apiKeyCache.mu.RLock()
	if !apiKeyCache.isExpired() {
		keys := apiKeyCache.keys
		apiKeyCache.mu.RUnlock()
		return keys, nil
	}
	apiKeyCache.mu.RUnlock()

	// Cache expired, fetch from Secrets Manager
	apiKeyCache.mu.Lock()
	defer apiKeyCache.mu.Unlock()

	// Double-check after acquiring write lock
	if !apiKeyCache.isExpired() {
		return apiKeyCache.keys, nil
	}

	result, err := smClient.GetSecretValue(ctx, &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(secretName),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to fetch secret %s: %w", secretName, err)
	}

	var keys map[string]string
	if err := json.Unmarshal([]byte(*result.SecretString), &keys); err != nil {
		return nil, fmt.Errorf("failed to parse secret JSON: %w", err)
	}

	apiKeyCache.keys = keys
	apiKeyCache.fetchedAt = time.Now()
	log.Printf("refreshed API keys from Secrets Manager, %d curators configured", len(keys))

	return keys, nil
}

func handler(ctx context.Context, req events.LambdaFunctionURLRequest) (events.LambdaFunctionURLResponse, error) {
	log.Printf("received %s request, path: %s", req.RequestContext.HTTP.Method, req.RawPath)

	// Only handle POST requests
	if req.RequestContext.HTTP.Method != http.MethodPost {
		return errorResponse(http.StatusMethodNotAllowed, "method not allowed"), nil
	}

	// Handle base64 encoded body (Lambda Function URLs encode the body)
	body := req.Body
	if req.IsBase64Encoded {
		decoded, err := base64.StdEncoding.DecodeString(req.Body)
		if err != nil {
			log.Printf("failed to decode base64 body: %v", err)
			return errorResponse(http.StatusBadRequest, "invalid request body"), nil
		}
		body = string(decoded)
	}

	// Parse the LFS batch request
	var batchReq BatchRequest
	if err := json.Unmarshal([]byte(body), &batchReq); err != nil {
		log.Printf("failed to parse request body: %v", err)
		return errorResponse(http.StatusBadRequest, "invalid request body"), nil
	}

	log.Printf("operation: %s, objects: %d", batchReq.Operation, len(batchReq.Objects))

	// Uploads require API key authentication
	if batchReq.Operation == "upload" {
		curator, ok, err := isAuthorized(ctx, req)
		if err != nil {
			log.Printf("error checking authorization: %v", err)
			return errorResponse(http.StatusInternalServerError, "internal error"), nil
		}
		if !ok {
			log.Printf("unauthorized upload attempt")
			return errorResponse(http.StatusUnauthorized, "unauthorized"), nil
		}
		log.Printf("authorized upload by curator: %s", curator)
	}

	// Generate pre-signed URLs for each object
	results := make([]LFSObjectResult, 0, len(batchReq.Objects))
	for _, obj := range batchReq.Objects {
		result, err := processObject(ctx, batchReq.Operation, obj)
		if err != nil {
			log.Printf("error processing object %s: %v", obj.OID, err)
			results = append(results, LFSObjectResult{
				OID:  obj.OID,
				Size: obj.Size,
				Error: &LFSObjectError{
					Code:    http.StatusInternalServerError,
					Message: "failed to generate URL",
				},
			})
			continue
		}
		results = append(results, result)
	}

	resp := BatchResponse{
		Transfer: "basic",
		Objects:  results,
	}

	respBody, err := json.Marshal(resp)
	if err != nil {
		log.Printf("failed to marshal response: %v", err)
		return errorResponse(http.StatusInternalServerError, "internal error"), nil
	}

	return events.LambdaFunctionURLResponse{
		StatusCode: http.StatusOK,
		Headers: map[string]string{
			"Content-Type": lfsContentType,
		},
		Body: string(respBody),
	}, nil
}

func processObject(ctx context.Context, operation string, obj LFSObject) (LFSObjectResult, error) {
	// S3 key derived from OID using standard LFS content-addressable layout
	// e.g. oid abc123... -> lfs/objects/ab/c1/abc123...
	key := fmt.Sprintf("lfs/objects/%s/%s/%s", obj.OID[:2], obj.OID[2:4], obj.OID)

	var href string
	var err error

	switch operation {
	case "download":
		href, err = presignGetURL(ctx, key)
	case "upload":
		href, err = presignPutURL(ctx, key)
	default:
		return LFSObjectResult{}, fmt.Errorf("unknown operation: %s", operation)
	}

	if err != nil {
		return LFSObjectResult{}, err
	}

	log.Printf("generated %s URL for oid %s", operation, obj.OID)

	return LFSObjectResult{
		OID:  obj.OID,
		Size: obj.Size,
		Actions: map[string]LFSAction{
			operation: {
				HREF:      href,
				ExpiresIn: urlExpiry,
			},
		},
	}, nil
}

func presignGetURL(ctx context.Context, key string) (string, error) {
	req, err := s3Presign.PresignGetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(bucketName),
		Key:    aws.String(key),
	}, s3.WithPresignExpires(time.Duration(urlExpiry)*time.Second))
	if err != nil {
		return "", fmt.Errorf("failed to presign GET: %w", err)
	}
	return req.URL, nil
}

func presignPutURL(ctx context.Context, key string) (string, error) {
	req, err := s3Presign.PresignPutObject(ctx, &s3.PutObjectInput{
		Bucket: aws.String(bucketName),
		Key:    aws.String(key),
	}, s3.WithPresignExpires(time.Duration(urlExpiry)*time.Second))
	if err != nil {
		return "", fmt.Errorf("failed to presign PUT: %w", err)
	}
	return req.URL, nil
}

// isAuthorized checks the request's Authorization header against all
// curator keys stored in Secrets Manager. Returns the curator name if
// authorized, so it can be logged for audit purposes.
func isAuthorized(ctx context.Context, req events.LambdaFunctionURLRequest) (string, bool, error) {
	auth := req.Headers["authorization"]
	if auth == "" {
		log.Printf("no authorization header present")
		return "", false, nil
	}

	var providedKey string

	// Handle Basic Auth (what git-lfs sends)
	// Format: "Basic base64(username:password)"
	// We only check the password against the API keys
	if strings.HasPrefix(auth, "Basic ") {
		decoded, err := base64.StdEncoding.DecodeString(strings.TrimPrefix(auth, "Basic "))
		if err != nil {
			log.Printf("failed to decode basic auth: %v", err)
			return "", false, nil
		}
		parts := strings.SplitN(string(decoded), ":", 2)
		if len(parts) != 2 {
			log.Printf("invalid basic auth format")
			return "", false, nil
		}
		providedKey = parts[1]
	} else if strings.HasPrefix(auth, "Bearer ") {
		providedKey = strings.TrimPrefix(auth, "Bearer ")
	} else {
		log.Printf("unrecognized auth scheme")
		return "", false, nil
	}

	// Fetch curator keys from Secrets Manager (cached)
	keys, err := getAPIKeys(ctx)
	if err != nil {
		return "", false, err
	}

	// Check provided key against all curator keys
	for curator, key := range keys {
		if providedKey == key {
			return curator, true, nil
		}
	}

	return "", false, nil
}

func errorResponse(statusCode int, message string) events.LambdaFunctionURLResponse {
	body, _ := json.Marshal(map[string]string{"message": message})
	return events.LambdaFunctionURLResponse{
		StatusCode: statusCode,
		Headers: map[string]string{
			"Content-Type": lfsContentType,
		},
		Body: string(body),
	}
}

func main() {
	lambda.Start(handler)
}
