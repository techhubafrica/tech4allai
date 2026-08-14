self.addEventListener("install", () => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      const cacheNames = await caches.keys();

      const flutterCacheNames = cacheNames.filter(
        (name) =>
          name === "flutter-app-cache" ||
          name === "flutter-temp-cache" ||
          name === "flutter-app-manifest" ||
          name.startsWith("flutter-")
      );

      await Promise.all(
        flutterCacheNames.map((name) =>
          caches.delete(name)
        )
      );

      await self.registration.unregister();

      const windows = await self.clients.matchAll({
        type: "window",
        includeUncontrolled: true
      });

      for (const client of windows) {
        client.navigate(client.url);
      }
    })()
  );
});
