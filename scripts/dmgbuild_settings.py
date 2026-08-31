application = defines["app"]
background = defines["background"]

format = "UDZO"
filesystem = "HFS+"

files = [(application, "HeicToJpegCompressor.app")]
symlinks = {"Applications": "/Applications"}
hide = [".background.png"]
hide_extensions = ["HeicToJpegCompressor.app"]

background = background
# Tahoe Finder can preserve a roughly 180 pt sidebar even when ShowSidebar is
# false. Reserve that width so the icon-view content still exposes the full
# 660 pt background canvas.
window_rect = ((20, 120), (840, 400))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False

icon_size = 100
text_size = 16
label_pos = "bottom"
arrange_by = None
icon_locations = {
    "HeicToJpegCompressor.app": (180, 140),
    "Applications": (480, 140),
}
