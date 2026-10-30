# File areas: uploads, images
Read 2026-10-30 from cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html, web.dev/articles/choose-the-right-image-format. Stack-neutral.

## uploads
- [ ] Extension allowlist of only business-needed types, checked after decoding the filename; reject names with a colon (NTFS alternate streams). Blocklists alone are weak. Source: https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html
- [ ] Never trust the client Content-Type header; check the real type against an allowlist (file signatures help but are not enough alone) (same source).
- [ ] Store under a server-generated random name (UUID); keep the user's name only as metadata, length-capped and character-restricted (same source).
- [ ] Hard size limit per file, and per request; for archives measure after decompression (same source).
- [ ] Store outside the webroot or on another host or object store; serve through a handler that maps an id to the file and re-checks permission; no per-directory config overrides in the upload directory (same source).
- [ ] Only authenticated users upload, with an ownership/permission check on read and write, and CSRF protection on the endpoint (same source; Protected Path in security skill, SOT).
- [ ] Scan with antivirus/sandbox where available; for images decode and re-encode to an allowed format and strip metadata, though rewriting does not guarantee malicious content is gone, so keep image libraries patched and resource-limited (same source).
- [ ] Log uploads (ops.md#logging) and apply rate limits (api.md#rate-limit).

## images
- [ ] Prefer no image or a vector (SVG) for logos/icons/simple graphics; raster only for photos and complex scenes. Source: https://web.dev/articles/choose-the-right-image-format
- [ ] Serve WebP or AVIF where possible with JPEG/PNG fallback; JPEG for photos, PNG only where lossless detail is needed; video instead of GIF for animation (same source).
- [ ] Serve responsive sizes: each doubling of screen resolution quadruples pixels, so a single large image wastes bytes on small screens (same source).
- [ ] Compress at upload or in a pipeline (generate a few sizes, strip metadata); try several quality levels per asset type, since the page gives no numeric value (same source).
- [ ] Mobile (APP): downscale and compress on the device before upload to save the user's data (general practice).

## UNVERIFIED
- OWASP page was read via a summarising fetch; SVG-specific upload risks (script in SVG) are NOT on that page, so SVG-sanitisation advice is general practice and not sourced.
- Specific JPEG/WebP quality numbers, max dimensions and CDN image-resizing options: not in the web.dev page, not read elsewhere.
- Presigned-URL direct-to-storage uploads, resumable/multipart uploads, and virus-scanner product choices: not read.
- web.dev responsive-images guide (srcset/sizes) is linked from the page but was not fetched.
