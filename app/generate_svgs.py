import os

def generate_all_svgs():
    # Make sure target directory exists
    icons_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "qml", "icons"))
    os.makedirs(icons_dir, exist_ok=True)
    print(f"Generating SVG icons under: {icons_dir}")

    svgs = {
        # ═══════════════════════════════
        #  状态/通知类 (Status Badges)
        # ═══════════════════════════════
        "success.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="10" fill="#07c160"/>
  <path d="M8 12.5l2.5 2.5 5.5-5.5" fill="none" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>""",

        "error.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="10" fill="#fa5151"/>
  <path d="M8.5 8.5l7 7M15.5 8.5l-7 7" fill="none" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>""",

        "warning.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2L2 22h20L12 2z" fill="#ffc300"/>
  <path d="M12 9v6" fill="none" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round"/>
  <circle cx="12" cy="18" r="1.25" fill="#ffffff"/>
</svg>""",

        "info.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="10" fill="#576b95"/>
  <path d="M12 11v6" fill="none" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round"/>
  <circle cx="12" cy="7" r="1.25" fill="#ffffff"/>
</svg>""",

        # ═══════════════════════════════
        #  文件类型类 (File Types)
        # ═══════════════════════════════
        "pdf.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <path d="M6 2h9l5 5v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2z" fill="#f8f9fa" stroke="#e74c3c" stroke-width="1.5"/>
  <path d="M14 2v5h5" fill="#e74c3c"/>
  <rect x="6" y="11" width="12" height="6" rx="1" fill="#e74c3c"/>
  <text x="12" y="15.5" fill="#ffffff" font-family="Segoe UI, sans-serif" font-size="4.5" font-weight="bold" text-anchor="middle">PDF</text>
</svg>""",

        "word.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <path d="M6 2h9l5 5v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2z" fill="#f8f9fa" stroke="#2b579a" stroke-width="1.5"/>
  <path d="M14 2v5h5" fill="#2b579a"/>
  <rect x="6" y="11" width="12" height="6" rx="1" fill="#2b579a"/>
  <text x="12" y="15.5" fill="#ffffff" font-family="Segoe UI, sans-serif" font-size="4.5" font-weight="bold" text-anchor="middle">DOC</text>
</svg>""",

        "excel.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <path d="M6 2h9l5 5v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2z" fill="#f8f9fa" stroke="#217346" stroke-width="1.5"/>
  <path d="M14 2v5h5" fill="#217346"/>
  <rect x="6" y="11" width="12" height="6" rx="1" fill="#217346"/>
  <text x="12" y="15.5" fill="#ffffff" font-family="Segoe UI, sans-serif" font-size="4.5" font-weight="bold" text-anchor="middle">XLS</text>
</svg>""",

        "image.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <path d="M6 2h9l5 5v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2z" fill="#f8f9fa" stroke="#3498db" stroke-width="1.5"/>
  <path d="M14 2v5h5" fill="#3498db"/>
  <circle cx="9.5" cy="11.5" r="1.5" fill="#3498db"/>
  <path d="M6 18l4-4 3.5 3.5M12 16l3-3 3 3" fill="none" stroke="#3498db" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>""",

        "file.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <path d="M6 2h9l5 5v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2z" fill="#f8f9fa" stroke="#7f8c8d" stroke-width="1.5"/>
  <path d="M14 2v5h5" fill="#7f8c8d"/>
  <path d="M8 12h8M8 15h8M8 18h5" fill="none" stroke="#bdc3c7" stroke-width="1.5" stroke-linecap="round"/>
</svg>""",

        # ═══════════════════════════════
        #  操作按钮类 (Actions)
        # ═══════════════════════════════
        "trash.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M10 11v6M14 11v6" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>""",

        "export.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <path d="M4 16v1a3 3 0 0 0 3 3h10a3 3 0 0 0 3-3v-1M12 2v13M8 11l4 4 4-4" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>""",

        "settings.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="3" fill="none" stroke="currentColor" stroke-width="2"/>
  <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>""",

        "play.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <path d="M5 3l14 9-14 9V3z" fill="currentColor"/>
</svg>""",

        "pause.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <rect x="6" y="4" width="4" height="16" rx="1" fill="currentColor"/>
  <rect x="14" y="4" width="4" height="16" rx="1" fill="currentColor"/>
</svg>""",

        "stop.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <rect x="4" y="4" width="16" height="16" rx="2" fill="currentColor"/>
</svg>""",

        "arrow_down.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <path d="M6 9l6 6 6-6" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>""",

        # ═══════════════════════════════
        #  空状态插图类 (Illustrations)
        # ═══════════════════════════════
        "chat_empty.svg": """<svg viewBox="0 0 64 64" width="64" height="64" xmlns="http://www.w3.org/2000/svg">
  <!-- Small bubble (White/Gray) -->
  <rect x="6" y="24" width="34" height="24" rx="8" fill="#f8f9fa" stroke="#e0e0e0" stroke-width="2"/>
  <path d="M12 48l-4 6 1-6" fill="#f8f9fa" stroke="#e0e0e0" stroke-width="2" stroke-linejoin="round"/>
  <!-- Lines inside small bubble -->
  <line x1="14" y1="32" x2="26" y2="32" stroke="#bdc3c7" stroke-width="2" stroke-linecap="round"/>
  <line x1="14" y1="38" x2="32" y2="38" stroke="#bdc3c7" stroke-width="2" stroke-linecap="round"/>

  <!-- Large bubble (WeChat Green) -->
  <rect x="22" y="10" width="36" height="26" rx="8" fill="#07c160" stroke="#06ad56" stroke-width="2"/>
  <path d="M50 36l4 6-1-6" fill="#07c160" stroke="#06ad56" stroke-width="2" stroke-linejoin="round"/>
  <!-- Checkmark inside green bubble -->
  <path d="M34 22l3 3 7-7" fill="none" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>""",

        "logs_empty.svg": """<svg viewBox="0 0 64 64" width="64" height="64" xmlns="http://www.w3.org/2000/svg">
  <!-- Clipboard body -->
  <rect x="14" y="16" width="36" height="42" rx="4" fill="#f8f9fa" stroke="#dcdde1" stroke-width="2"/>
  <!-- Header clip -->
  <rect x="26" y="8" width="12" height="12" rx="2" fill="#7f8c8d" stroke="#7f8c8d" stroke-width="1"/>
  <circle cx="32" cy="12" r="2" fill="#ffffff"/>
  <!-- Document rows -->
  <line x1="20" y1="28" x2="44" y2="28" stroke="#bdc3c7" stroke-width="2" stroke-linecap="round"/>
  <line x1="20" y1="36" x2="38" y2="36" stroke="#bdc3c7" stroke-width="2" stroke-linecap="round"/>
  <line x1="20" y1="44" x2="44" y2="44" stroke="#bdc3c7" stroke-width="2" stroke-linecap="round"/>
  <!-- Subtle log check -->
  <circle cx="40" cy="36" r="3" fill="#07c160" opacity="0.8"/>
  <path d="M38.5 36l1 1 2-2" fill="none" stroke="#ffffff" stroke-width="1" stroke-linecap="round" stroke-linejoin="round"/>
</svg>""",

        # ═══════════════════════════════
        #  Phase 1 (V4) 新增 — 标准操作图标
        # ═══════════════════════════════
        "cut.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="6" cy="6" r="2.5" fill="none" stroke="currentColor" stroke-width="1.8"/>
  <circle cx="6" cy="18" r="2.5" fill="none" stroke="currentColor" stroke-width="1.8"/>
  <path d="M8 7l8 6M8 17l8-6" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
</svg>""",

        "copy.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <rect x="9" y="9" width="11" height="11" rx="2" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>
  <path d="M6 15H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v1" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>
</svg>""",

        "paste.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>
  <rect x="8" y="2" width="8" height="4" rx="1" fill="none" stroke="currentColor" stroke-width="1.8"/>
</svg>""",

        "folder_open.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <path d="M22 19V9a1 1 0 0 0-1-1h-6.5l-1.7-2.6A1 1 0 0 0 11 5H3a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h18a1 1 0 0 0 1-1z" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>
</svg>""",

        "text_cursor.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 3v18M9 6h6M9 18h6" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
</svg>""",

        "clear_all.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <path d="M5 8h14M8 8l2 10h4l2-10M10 5h4" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>""",

        "select_all.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <rect x="4" y="4" width="16" height="16" rx="2" fill="none" stroke="currentColor" stroke-width="1.8"/>
  <path d="M8 12l2.5 2.5L16 9" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>""",

        "user.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="8" r="4" fill="#bdbdbd"/>
  <path d="M4 20c0-4.4 3.6-8 8-8s8 3.6 8 8" fill="#bdbdbd"/>
</svg>""",

        "send.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <path d="M22 2L11 13M22 2l-7 20-4-9-9-4 20-7z" fill="currentColor" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>""",

        "clock.svg": """<svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="1.8"/>
  <path d="M12 7v5l3 3" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
</svg>"""
    }

    # Write each file
    for filename, content in svgs.items():
        filepath = os.path.join(icons_dir, filename)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"  Written: {filename}")

if __name__ == "__main__":
    generate_all_svgs()
