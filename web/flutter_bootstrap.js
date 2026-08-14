{{flutter_js}}
{{flutter_build_config}}

const VERSION_URL = "/version.json";

let bootBuildId = null;
let checkingForUpdate = false;

async function fetchLatestBuildId(timeoutMs = 1500) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(VERSION_URL, {
      cache: "no-store",
      signal: controller.signal,
      headers: {
        "Cache-Control": "no-cache"
      }
    });

    if (!response.ok) {
      throw new Error(`Version request failed: ${response.status}`);
    }

    const data = await response.json();
    return String(data.buildId || data.version || "");
  } catch (error) {
    console.warn("Could not check the latest build:", error);
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

function versionFlutterEntrypoints(buildId) {
  if (!buildId || !_flutter.buildConfig?.builds) {
    return;
  }

  for (const build of _flutter.buildConfig.builds) {
    if (build.mainJsPath) {
      const originalPath = build.mainJsPath.split("?")[0];

      build.mainJsPath =
        `${originalPath}?build=${encodeURIComponent(buildId)}`;
    }

    if (build.mainWasmPath) {
      const originalPath = build.mainWasmPath.split("?")[0];

      build.mainWasmPath =
        `${originalPath}?build=${encodeURIComponent(buildId)}`;
    }

    if (build.jsSupportRuntimePath) {
      const originalPath =
        build.jsSupportRuntimePath.split("?")[0];

      build.jsSupportRuntimePath =
        `${originalPath}?build=${encodeURIComponent(buildId)}`;
    }
  }
}

async function checkForNewDeployment() {
  if (checkingForUpdate || !bootBuildId) {
    return;
  }

  checkingForUpdate = true;

  try {
    const latestBuildId = await fetchLatestBuildId();

    if (
      latestBuildId &&
      latestBuildId !== bootBuildId
    ) {
      window.location.reload();
    }
  } finally {
    checkingForUpdate = false;
  }
}

async function startFlutter() {
  const latestBuildId = await fetchLatestBuildId();

  bootBuildId = latestBuildId || "unknown";

  /*
   * This versions main.dart.js—not merely flutter_bootstrap.js.
   * A new Git commit therefore produces a new browser URL.
   */
  versionFlutterEntrypoints(latestBuildId);

  _flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
      const appRunner =
        await engineInitializer.initializeEngine();

      await appRunner.runApp();

      const loader =
        document.getElementById("app-loader");

      if (loader) {
        loader.classList.add("hidden");

        setTimeout(() => {
          loader.remove();
        }, 250);
      }
    }
  });
}

window.addEventListener("pageshow", () => {
  checkForNewDeployment();
});

document.addEventListener("visibilitychange", () => {
  if (!document.hidden) {
    checkForNewDeployment();
  }
});

startFlutter();
