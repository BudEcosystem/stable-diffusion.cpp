#ifndef __EXAMPLES_COMMON_GENERATION_METADATA_H__
#define __EXAMPLES_COMMON_GENERATION_METADATA_H__

#include <cstdint>
#include <string>
#include <utility>
#include <vector>

std::string merge_generation_info(const std::string& source, const std::string& operation);
std::string generation_info_with_relative_lora_paths(const std::string& info, const std::string& lora_model_dir);
// Rewrites absolute paths, and relative paths that climb out with "..", under
// `path` and `*_path` keys: relative to the first containing root (prefixed by
// the root's name), otherwise as the bare file name.
std::string generation_info_without_paths(const std::string& info,
                                          const std::vector<std::pair<std::string, std::string>>& roots);
int64_t generation_seed(const std::string& info, int64_t fallback = -1);
std::string generation_info_to_webui(const std::string& text);
std::string generation_info_to_image_metadata(const std::string& info);

#endif  // __EXAMPLES_COMMON_GENERATION_METADATA_H__
