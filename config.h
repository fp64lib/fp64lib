/* We don't use autoconf, so assume the tools have been configured as needed. */

/* Define if 64-bit double comparisons return bool. */
/* #undef DOUBLE_COMPARE_BOOL */

/* Define if 64-bit double comparisons return tristate. */
/* #undef DOUBLE_COMPARE_TRISTATE */

#if defined(__WITH_DOUBLE_COMPARISON__)
#if __WITH_DOUBLE_COMPARISON__ == 2
#define DOUBLE_COMPARE_BOOL
#endif
#endif

#if !defined(DOUBLE_COMPARE_BOOL)
#define DOUBLE_COMPARE_TRISTATE
#endif

/* Define if ld supports .gnu_attribute 12 (Tag_GNU_AVR_BITS_LONG_DOUBLE). */
/* #undef HAVE_LD_GNU_ATTRIBUTE_12 */

/* Define if ld supports .gnu_attribute 8 (Tag_GNU_AVR_BITS_DOUBLE). */
/* #undef HAVE_LD_GNU_ATTRIBUTE_8 */
