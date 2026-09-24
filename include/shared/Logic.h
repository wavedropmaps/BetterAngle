#ifndef LOGIC_H
#define LOGIC_H

#include <mutex>
#include <windows.h>

// Converts raw mouse X counts into a camera yaw angle (degrees, 0-360).
//
// The angle is integrated delta-by-delta rather than recomputed from a total
// count, so a sensitivity change or dive/glide scale switch only affects
// movement that happens after it. All state sits behind one mutex: Update()
// runs on the raw-input thread while the detector thread switches scales and
// the HUD reads the angle.
class AngleLogic {
public:
  // Fortnite yaw: degrees per mouse count at sensitivity 1.0.
  static constexpr double kDegreesPerCount = 0.00555555;
  // Skydiving turns ~9% faster than gliding at the same sensitivity.
  static constexpr double kDiveMultiplier = 1.0916;

  explicit AngleLogic(double sensX);

  void Update(int dx);
  double GetAngle() const;
  void SetZero();
  void SetSensitivity(double sensX);

  // Switch between the glide and dive scale. blendMs == 0 switches instantly
  // (used with the BlockInput lock, where no movement happens mid-change).
  // blendMs > 0 eases the scale from its current value to the new one over
  // that many milliseconds, so movement during the game's FOV transition is
  // still counted at close to the right rate.
  void SetDivingState(bool diving, int blendMs);

  // True once the mouse moved during a blend: the reading now includes
  // estimated movement. Cleared by SetZero().
  bool IsEstimated() const;

private:
  double CurrentMultiplier(ULONGLONG now) const; // caller holds m_mutex
  static double Norm360(double a);

  mutable std::mutex m_mutex;
  double m_sensX;
  bool m_isDiving = false;
  double m_angle = 0.0;

  double m_blendFrom = 1.0;
  double m_blendTo = 1.0;
  ULONGLONG m_blendStart = 0;
  int m_blendMs = 0;
  bool m_estimated = false;
};

#endif // LOGIC_H
