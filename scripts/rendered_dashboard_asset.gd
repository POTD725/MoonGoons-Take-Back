class_name RenderedDashboardAsset
extends RefCounted
## Reassembles the approved rendered Take Back dashboard from repository-safe
## text chunks and validates it before the game is allowed to display it.

const CHUNK_DIRECTORY: String = "res://assets/approved/master_dashboard_chunks"
const CHUNK_COUNT: int = 6
const EXPECTED_WIDTH: int = 360
const EXPECTED_HEIGHT: int = 540
const EXPECTED_BASE64_LENGTH: int = 41568

static func load_image() -> Image:
	var encoded: String = encoded_payload()
	if encoded.length() != EXPECTED_BASE64_LENGTH:
		push_error("Rendered dashboard payload length mismatch: %d" % encoded.length())
		return null
	var bytes: PackedByteArray = Marshalls.base64_to_raw(encoded)
	if bytes.is_empty():
		push_error("Rendered dashboard payload did not decode.")
		return null
	var image := Image.new()
	var error: Error = image.load_jpg_from_buffer(bytes)
	if error != OK:
		push_error("Rendered dashboard JPEG failed to load: %s" % error_string(error))
		return null
	if image.get_width() != EXPECTED_WIDTH or image.get_height() != EXPECTED_HEIGHT:
		push_error("Rendered dashboard dimensions were %dx%d, expected %dx%d." % [image.get_width(), image.get_height(), EXPECTED_WIDTH, EXPECTED_HEIGHT])
		return null
	return image

static func load_texture() -> Texture2D:
	var image: Image = load_image()
	if image == null:
		return null
	return ImageTexture.create_from_image(image)

static func encoded_payload() -> String:
	var encoded: String = ""
	for index: int in range(CHUNK_COUNT):
		var path: String = "%s/chunk_%02d.txt" % [CHUNK_DIRECTORY, index]
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("Missing rendered dashboard chunk: %s" % path)
			return ""
		encoded += file.get_as_text().strip_edges()
	return encoded
