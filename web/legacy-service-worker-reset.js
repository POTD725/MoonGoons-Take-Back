/*
 * One-release cleanup worker for the former MoonGoons PWA export.
 * The old Godot worker cached a threaded-worker dependency that was not shipped
 * and could trap browsers on a nearly complete loading bar. This replacement
 * clears those caches, unregisters itself, and reloads controlled pages from
 * the network.
 */
const MOONGOONS_CACHE_PREFIX = 'MoonGoons Take B-sw-cache-';

self.addEventListener('install', (event) => {
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(
      keys
        .filter((key) => key.startsWith(MOONGOONS_CACHE_PREFIX))
        .map((key) => caches.delete(key))
    );

    await self.clients.claim();
    const clients = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    await self.registration.unregister();

    for (const client of clients) {
      const url = new URL(client.url);
      url.searchParams.set('webfix', '2');
      client.navigate(url.toString());
    }
  })());
});

self.addEventListener('fetch', (event) => {
  event.respondWith(fetch(event.request, { cache: 'no-store' }));
});
