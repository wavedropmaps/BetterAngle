// Force-included for MSVC builds (see CMakeLists.txt).
//
// Qt 6.5's headers (qvarlengtharray.h) call
// stdext::make_checked_array_iterator, which the MSVC STL removed in the
// VS 2026 toolset (_MSC_VER 1950+). Provide a pass-through replacement so Qt
// 6.5 still compiles; it just returns the raw pointer, which is all an
// unchecked release build used anyway. Older toolsets still ship the real
// function, so this only kicks in where it's missing.
#pragma once
#if defined(_MSC_VER) && !defined(__clang__) && _MSC_VER >= 1950
#include <cstddef>
namespace stdext {
template <class T>
inline T *make_checked_array_iterator(T *ptr, std::size_t, std::size_t = 0) {
  return ptr;
}
} // namespace stdext
#endif
