#include "shared/Logic.h"
#include <cmath>

AngleLogic::AngleLogic(double sensX) : m_sensX(sensX) {}

double AngleLogic::CurrentMultiplier(ULONGLONG now) const {
  if (m_blendMs <= 0 || now >= m_blendStart + (ULONGLONG)m_blendMs)
    return m_blendTo;
  double t = (double)(now - m_blendStart) / (double)m_blendMs;
  return m_blendFrom + (m_blendTo - m_blendFrom) * t;
}

void AngleLogic::Update(int dx) {
  if (dx == 0)
    return;
  std::lock_guard<std::mutex> lock(m_mutex);
  ULONGLONG now = GetTickCount64();
  if (m_blendMs > 0 && now < m_blendStart + (ULONGLONG)m_blendMs)
    m_estimated = true;
  m_angle = Norm360(m_angle + dx * kDegreesPerCount * m_sensX *
                                  CurrentMultiplier(now));
}

double AngleLogic::GetAngle() const {
  std::lock_guard<std::mutex> lock(m_mutex);
  return m_angle;
}

void AngleLogic::SetZero() {
  std::lock_guard<std::mutex> lock(m_mutex);
  m_angle = 0.0;
  m_estimated = false;
}

void AngleLogic::SetSensitivity(double sensX) {
  std::lock_guard<std::mutex> lock(m_mutex);
  m_sensX = sensX;
}

void AngleLogic::SetDivingState(bool diving, int blendMs) {
  std::lock_guard<std::mutex> lock(m_mutex);
  if (diving == m_isDiving)
    return;
  ULONGLONG now = GetTickCount64();
  // Start from wherever the scale is right now so a reversal mid-blend
  // doesn't jump.
  m_blendFrom = CurrentMultiplier(now);
  m_blendTo = diving ? kDiveMultiplier : 1.0;
  m_blendStart = now;
  m_blendMs = blendMs > 0 ? blendMs : 0;
  m_isDiving = diving;
}

bool AngleLogic::IsEstimated() const {
  std::lock_guard<std::mutex> lock(m_mutex);
  return m_estimated;
}

double AngleLogic::Norm360(double a) {
  a = std::fmod(a, 360.0);
  if (a < 0.0)
    a += 360.0;
  return a;
}
