const CACHE_NAME = 'tech4all-proxy-bypass-v2';

self.addEventListener('install', (event) => {
    console.log('[Proxy SW] Installing...');
    // Force the new taking over immediately
    self.skipWaiting();
});

self.addEventListener('activate', (event) => {
    console.log('[Proxy SW] Activating and destroying old caches...');
    event.waitUntil(
        caches.keys().then((cacheNames) => {
            return Promise.all(
                cacheNames.map((cacheName) => {
                    console.log('[Proxy SW] Deleting cache:', cacheName);
                    return caches.delete(cacheName);
                })
            );
        }).then(() => {
            console.log('[Proxy SW] Claiming clients...');
            return self.clients.claim();
        })
    );
});

self.addEventListener('fetch', (event) => {
    if (event.request.method !== 'GET') {
        return; // Let browser handle POST etc.
    }

    // Completely bypass the browser HTTP cache to enforce fresh fetches
    event.respondWith(
        fetch(event.request, { cache: 'reload' }).catch((error) => {
            console.error('[Proxy SW] Normal network fetch failed, trying with cache-busting URL parameter', error);
            
            // If the strict 'reload' header fails (some old mobile Chrome versions),
            // physically mutate the URL string with a cache-busting timestamp
            try {
                const url = new URL(event.request.url);
                url.searchParams.set('fw-bypass', Date.now());
                return fetch(url.toString(), { cache: 'reload' });
            } catch (e) {
                // If it's a cross-origin request that fails URL parsing, fallback
                return fetch(event.request);
            }
        })
    );
});
