#include "shared/Detector.h"


FovDetector::FovDetector()
    : m_hdcScreen(NULL), m_hdcMem(NULL), m_hbm(NULL), m_hOld(NULL), m_curW(0),
      m_curH(0), m_pixels(NULL) {}

FovDetector::~FovDetector() {
  if (m_hdcMem) {
    SelectObject(m_hdcMem, m_hOld);
    DeleteDC(m_hdcMem);
  }
  if (m_hbm)
    DeleteObject(m_hbm);
  if (m_hdcScreen)
    ReleaseDC(NULL, m_hdcScreen);
}

void FovDetector::EnsureScreenDC() {
  if (!m_hdcScreen) {
    m_hdcScreen = GetDC(NULL);
  }
}

void FovDetector::EnsureResources(int w, int h) {
  EnsureScreenDC();
  if (w == m_curW && h == m_curH && m_hdcMem)
    return;

  if (m_hdcMem) {
    SelectObject(m_hdcMem, m_hOld);
    DeleteDC(m_hdcMem);
    DeleteObject(m_hbm);
  }

  m_hdcMem = CreateCompatibleDC(m_hdcScreen);

  BITMAPINFO bmi = {0};
  bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth = w;
  bmi.bmiHeader.biHeight = -h; // Top-down
  bmi.bmiHeader.biPlanes = 1;
  bmi.bmiHeader.biBitCount = 32;
  bmi.bmiHeader.biCompression = BI_RGB;

  m_pixels = NULL;
  m_hbm =
      CreateDIBSection(m_hdcScreen, &bmi, DIB_RGB_COLORS, &m_pixels, NULL, 0);
  if (!m_hbm || !m_pixels) {
    // Allocation failed (GDI exhaustion or an absurd ROI size). Leave the
    // cache invalid so the next scan retries instead of reading NULL.
    DeleteDC(m_hdcMem);
    m_hdcMem = NULL;
    if (m_hbm)
      DeleteObject(m_hbm);
    m_hbm = NULL;
    m_pixels = NULL;
    m_curW = m_curH = 0;
    return;
  }
  m_hOld = SelectObject(m_hdcMem, m_hbm);
  m_curW = w;
  m_curH = h;
}

// Count ROI pixels within `tolerance` (Euclidean RGB distance) of the target
// colour. Plain integer loop; the compiler vectorises it well.
int FovDetector::Scan(const RoiConfig &cfg) {
  if (cfg.w <= 0 || cfg.h <= 0)
    return 0;

  EnsureResources(cfg.w, cfg.h);
  if (!m_pixels)
    return 0;
  BitBlt(m_hdcMem, 0, 0, cfg.w, cfg.h, m_hdcScreen, cfg.x, cfg.y, SRCCOPY);

  const int totalPixels = cfg.w * cfg.h;
  const int tolSq = cfg.tolerance * cfg.tolerance;
  const int tr = (int)GetRValue(cfg.target);
  const int tg = (int)GetGValue(cfg.target);
  const int tb = (int)GetBValue(cfg.target);

  const DWORD *p = (const DWORD *)m_pixels;
  int match = 0;
  for (int i = 0; i < totalPixels; i++) {
    DWORD pix = p[i]; // BGRA in memory -> 0xAARRGGBB
    int dr = (int)((pix >> 16) & 0xFF) - tr;
    int dg = (int)((pix >> 8) & 0xFF) - tg;
    int db = (int)(pix & 0xFF) - tb;
    if (dr * dr + dg * dg + db * db <= tolSq)
      match++;
  }
  return match;
}
