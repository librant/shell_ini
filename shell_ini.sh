#!/bin/bash

# 判断 INI 文件中是否存在对应 section, 不存在则创建
# add_section_to_ini "$config_file" "$section"
function add_section_to_ini() {
  local ini_file="$1"
  local section_name="$2"
    
  if grep -q "^\[$section_name\]" "$ini_file"; then
    echo "Section [$section_name] already exists in $ini_file."
    return 0
  else
    echo "[$section_name]" >> "$ini_file"
    echo "Creating section [$section_name] in $ini_file..."
    return 1
  fi
}

# 在 INI 文件中添加或修改键值对
# 参数: 文件名, 节名, 键名, 值
# add_key_value_to_section "$config_file" "$section" "$key" "$value"
function add_key_value_to_section() {
  local ini_file="$1"
  local section_name="$2"
  local key="$3"
  local value="$4"

  if grep -q "^\[$section_name\]" "$ini_file"; then
    # Section exists
    if grep -q "^[[:space:]]*$key[[:space:]]*=" "$ini_file"; then
      # Key exists, skip adding
      echo "Key $key already exists in section [$section_name] of $ini_file. Skipping..."
      return 0
    else
      # Key does not exist, add key-value pair
      awk -v key="$key" -v value="$value" -v section_name="$section_name" '
        /^\[.*\]/ {
          if ($0 == "[" section_name "]") {
            print $0
            print key "=" value
          } else {
            print $0
          }
        }
        !/^\[.*\]/ { print }
        ' "$ini_file" > "$ini_file.tmp" && mv "$ini_file.tmp" "$ini_file"

      echo "Added key $key=$value to section [$section_name] in $ini_file."
      return 0
    fi
  else
    echo "Section [$section_name] does not exist in $ini_file."
    return 1
  fi
}

# 在 INI 文件中删除键值对
# 参数: 文件名, 节名, 键名
# delete_key_in_section "$config_file" "$section" "$key"
function delete_key_in_section() {
  local ini_file="$1"
  local section_name="$2"
  local key="$3"

  if grep -q "^\[$section_name\]" "$ini_file"; then
    # Section exists
    if grep -q "^[[:space:]]*$key[[:space:]]*=" "$ini_file"; then
      # Key exists, delete key
      awk -v key="$key" -v section_name="$section_name" '
                {
                    if ($0 == "[" section_name "]") {
                        in_section = 1
                    } else if ($0 ~ /^\[/) {
                        in_section = 0
                    }

                    if (!in_section || !($0 ~ "^[[:space:]]*" key "[[:space:]]*=")) {
                        print
                    }
                }
            ' "$ini_file" > "$ini_file.tmp" && mv "$ini_file.tmp" "$ini_file"

      echo "Deleted key $key in section [$section_name] of $ini_file."
    else
      echo "Key $key does not exist in section [$section_name] of $ini_file."
    fi
  else
    echo "Section [$section_name] does not exist in $ini_file."
  fi
}

# 在 INI 文件中修改键值
# 参数: 文件名, 节名, 键名，值
# modify_key_value "$config_file" "$section" "$key" "$value"
function modify_key_value() {
  local ini_file="$1"
  local section_name="$2"
  local key="$3"
  local new_value="$4"

  if grep -q "^\[$section_name\]" "$ini_file"; then
    # Section exists
    if grep -q "^[[:space:]]*$key[[:space:]]*=" "$ini_file"; then
      # Key exists, modify value
      awk -v key="$key" -v new_value="$new_value" -v section_name="$section_name" '
                {
                    if ($0 == "[" section_name "]") {
                        in_section = 1
                    } else if ($0 ~ /^\[/) {
                        in_section = 0
                    }

                    if (in_section && $0 ~ "^[[:space:]]*" key "[[:space:]]*=") {
                        sub(/=[[:space:]]*.*/, "= " new_value)
                    }

                    print
                }
            ' "$ini_file" > "$ini_file.tmp" && mv "$ini_file.tmp" "$ini_file"

      echo "Modified key $key in section [$section_name] to $new_value in $ini_file."
    else
      echo "Key $key does not exist in section [$section_name] of $ini_file."
    fi
  else
    echo "Section [$section_name] does not exist in $ini_file."
  fi
}

# 在 INI 文件中读取键值
# 参数: 文件名, 节名, 键名
# read_key_value "$config_file" "$section" "$key"
function read_key_value() {
  local ini_file="$1"
  local section_name="$2"
  local key="$3"

  if grep -q "^\[$section_name\]" "$ini_file"; then
    # Section exists
    if grep -q "^[[:space:]]*$key[[:space:]]*=" "$ini_file"; then
      # Key exists, read value
      value=$(awk -F '=' -v key="$key" -v section_name="$section_name" '
                $0 ~ /^\[/ { in_section = ($0 == "[" section_name "]") }

                in_section && $1 == key {
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
                    print $2
                    exit
                }
            ' "$ini_file")

      echo "Value of key $key in section [$section_name] is: $value"
    else
      echo "Key $key does not exist in section [$section_name] of $ini_file."
    fi
  else
    echo "Section [$section_name] does not exist in $ini_file."
  fi
}
