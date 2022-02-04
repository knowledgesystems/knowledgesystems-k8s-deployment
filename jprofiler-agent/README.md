# JProfiler Agent for cBioPortal Backend

This folder contains files and information helpful to setup a JProfiler agent in a pod running an instance of the cBioPortal backend.  It consists of a dockerfile which builds a container image that contains a JProfiler_agent distribution and a cBioPortal backend deployment file. 

## JProfiler agent docker file
This dockerfile should be updated to reference a version of an agent that matches the GUI client application.  The proper version can be found via the "Help" menu item in the client and following the "Show Profile Agent Downloads" option.  The distribution file should be updated in the docker file at [./jprofiler-client-dockerfile](./jprofiler-client-dockerfile).  The image is placed in the cbioportal/jprofile-agent repository, with a tag corresponding to the version of the agent.

## Deployment File
The deployment file  [../cbioportal/cbioportal_backend_jprofiler_agent.yaml](../cbioportal/cbioportal_backend_jprofiler_agent.yaml) makes reference to the JProfiler agent container image tag via the "initContainers" spec.  It makes the agent accessible to the cBioPortal backend via volume/volume mount declarations. It also adds the following JVM argument:

```
-agentpath:/jprofiler-agent/bin/linux-x64/libjprofilerti.so=port=2718,nowait
```
The port referenced here should be reflected in the kubectl port-forward command as well as the remote connection configuration set in the JProfiler client (more below**.

## Runtime configuration
After the deployment file is running on the remote machine the following steps should be followed:
* ssh to the remote machine and forward a local port to the port on the pod opened up by the JProfiler agent as referenced in the deployment file.
```
kubectl port-forward cbioportal-backend-jprofiler-agent-54fd4cb548-4jpl2 2718:2718
```

* Start the JProfiler client and setup a connection "On another computer" via an SSH tunnel. Be sure to manually specify the profiling port.  Once again, this port should correspond to the port on the pod opened up by the JProfiler agent referenced in the deployment file (and port-forwarded in the prior step**.

## Happy JProfiling!

