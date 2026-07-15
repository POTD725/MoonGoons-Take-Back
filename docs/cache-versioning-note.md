# Browser package versioning

GitHub Pages may retain an older `index.pck` in the browser HTTP cache even after `index.html` is updated. The Pages workflow renames the exported PCK with the current commit SHA and rewrites the generated Godot configuration to that unique filename. This keeps the HTML shell, game scripts, scenes, and artwork on the same release and prevents the Campaign Hub shell from launching an older RTS package.
