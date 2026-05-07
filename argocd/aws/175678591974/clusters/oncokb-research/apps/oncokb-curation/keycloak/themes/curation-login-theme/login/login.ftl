<!DOCTYPE html>
<html lang="${locale.currentLanguageTag!'en'}">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${msg("loginTitle",(realm.displayName!''))}</title>

    <link rel="icon" type="image/png" href="${url.resourcesPath}/img/favicon.png" />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Newsreader:ital,wght@0,500;1,500&family=IBM+Plex+Mono:wght@400;500&display=swap" rel="stylesheet" />

    <#if properties.styles?has_content>
        <#list properties.styles?split(' ') as style>
            <link href="${url.resourcesPath}/${style}" rel="stylesheet" />
        </#list>
    </#if>

    <#if scripts??>
        <#list scripts as script>
            <script src="${script}" type="text/javascript"></script>
        </#list>
    </#if>
</head>
<body class="ock-body">

<div class="ock-frame">

    <aside class="ock-panel">
        <div class="ock-panel__bg" aria-hidden="true"></div>

        <header class="ock-panel__header">
            <img class="ock-logo ock-logo--light" src="${url.resourcesPath}/img/oncokb-logo.png" alt="OncoKB" />
            <span class="ock-mono ock-eyebrow ock-eyebrow--onDark">CURATION PLATFORM</span>
        </header>

        <div class="ock-panel__body">
            <svg class="ock-motif" viewBox="0 0 520 220" preserveAspectRatio="none" aria-hidden="true">
                <g fill="rgba(255,255,255,0.85)">
                    <rect x="0"   y="60" width="52" height="14" rx="2"/>
                    <rect x="98"  y="60" width="14" height="14" rx="2"/>
                    <rect x="140" y="60" width="28" height="14" rx="2"/>
                    <rect x="210" y="60" width="70" height="14" rx="2"/>
                    <rect x="294" y="60" width="14" height="14" rx="2"/>
                    <rect x="322" y="60" width="42" height="14" rx="2"/>
                    <rect x="378" y="60" width="56" height="14" rx="2"/>
                </g>
                <g fill="rgba(255,255,255,0.55)">
                    <rect x="0"   y="96" width="28" height="14" rx="2"/>
                    <rect x="42"  y="96" width="56" height="14" rx="2"/>
                    <rect x="126" y="96" width="42" height="14" rx="2"/>
                    <rect x="196" y="96" width="14" height="14" rx="2"/>
                    <rect x="224" y="96" width="14" height="14" rx="2"/>
                    <rect x="252" y="96" width="70" height="14" rx="2"/>
                    <rect x="350" y="96" width="28" height="14" rx="2"/>
                </g>
                <g fill="rgba(255,255,255,0.30)">
                    <rect x="0"   y="132" width="42" height="14" rx="2"/>
                    <rect x="56"  y="132" width="28" height="14" rx="2"/>
                    <rect x="98"  y="132" width="14" height="14" rx="2"/>
                    <rect x="126" y="132" width="56" height="14" rx="2"/>
                    <rect x="196" y="132" width="28" height="14" rx="2"/>
                    <rect x="238" y="132" width="28" height="14" rx="2"/>
                    <rect x="280" y="132" width="42" height="14" rx="2"/>
                </g>
            </svg>

            <h2 class="ock-tagline">
                A precision oncology<br/>knowledge base
            </h2>
            <p class="ock-tagline__sub">
                The internal platform for OncoKB<sup>TM</sup> Scientific Content Management
            </p>
        </div>

        <footer class="ock-panel__footer">
            <div class="ock-attribution ock-attribution--onDark">
                Maintained by <a class="ock-attr-link" href="https://oncokb.org" target="_blank" rel="noopener">OncoKB<sup>TM</sup></a> · <a class="ock-attr-link" href="https://www.mskcc.org" target="_blank" rel="noopener">Memorial Sloan Kettering Cancer Center</a>
            </div>
            <span class="ock-mono ock-fineprint">FDA-RECOGNIZED HUMAN GENETIC VARIANT DATABASE</span>
        </footer>
    </aside>

    <main class="ock-main">

        <div class="ock-main__center">
            <div class="ock-card">
                <h1 class="ock-card__title">Welcome back!</h1>
                <p class="ock-card__sub">Sign in with your Google account to continue.</p>

                <div class="ock-providers">
                    <#list social.providers as p>
                        <a class="ock-google-btn ock-google-btn--google"
                           id="social-${p.alias}"
                           href="${p.loginUrl}">
                            <svg class="ock-g-icon" width="18" height="18" viewBox="0 0 18 18" aria-hidden="true">
                                <path fill="#4285F4" d="M17.64 9.2c0-.64-.06-1.25-.16-1.84H9v3.48h4.84a4.14 4.14 0 0 1-1.8 2.72v2.26h2.92c1.71-1.58 2.7-3.9 2.7-6.62z"/>
                                <path fill="#34A853" d="M9 18c2.43 0 4.47-.81 5.96-2.18l-2.92-2.26c-.81.54-1.85.86-3.04.86-2.34 0-4.32-1.58-5.03-3.7H.9v2.33A9 9 0 0 0 9 18z"/>
                                <path fill="#FBBC05" d="M3.97 10.72A5.4 5.4 0 0 1 3.68 9c0-.6.1-1.18.29-1.72V4.95H.9A9 9 0 0 0 0 9c0 1.45.35 2.82.9 4.05l3.07-2.33z"/>
                                <path fill="#EA4335" d="M9 3.58c1.32 0 2.51.45 3.44 1.35l2.58-2.58A8.99 8.99 0 0 0 9 0 9 9 0 0 0 .9 4.95l3.07 2.33C4.68 5.16 6.66 3.58 9 3.58z"/>
                            </svg>
                            <span>Continue with ${p.displayName!"Google"}</span>
                        </a>
                    </#list>
                </div>

                <#if message?has_content && message.type != 'success'>
                    <div class="ock-error" style="margin-top:14px">${kcSanitize(message.summary)?no_esc}</div>
                </#if>

                <div class="ock-divider">
                    <span class="ock-mono">AUTHORIZED USERS ONLY</span>
                </div>

                <div class="ock-help">
                    Need access? Request an account from developers.
                </div>
            </div>
        </div>

    </main>

</div>

</body>
</html>
