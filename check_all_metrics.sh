#!/bin/bash

echo "🔍 Scanning each *metrics.rs* file for defined metrics and checking usage in the same file..."
echo

# Step 1: Find all metrics.rs files
metrics_files=$(find . -name "metrics.rs")

# Step 2: For each metrics.rs file
for file in $metrics_files; do
  echo "📄 Checking file: $file"

  # Extract metric fields defined in this file using ripgrep + PCRE2
  fields=$(rg -o --pcre2 'pub (\w+): (Shared(?:Inc|Store)Metric|LatencyAggregateMetrics)' "$file")

  if [[ -z "$fields" ]]; then
    echo "   ⚠️  No metric fields found in $file"
    echo
    continue
  fi

  # Step 3: For each field, check for usage in this file
  while read -r line; do
    field=$(echo "$line" | awk '{print $2}')
    type=$(echo "$line" | awk '{print $3}')

    echo -n "   🔍 $field ($type): "

    # Define usage patterns based on type
    patterns=()
    if [[ "$type" == "SharedIncMetric" || "$type" == "SharedStoreMetric" ]]; then
      patterns+=("${field}.*\\.store" "${field}.*\\.inc" "${field}.*\\.add" "${field}.*\\.fetch")
    elif [[ "$type" == "LatencyAggregateMetrics" ]]; then
      patterns+=("${field}.*\\.record_latency_metrics")
    fi

    used=false
    for pattern in "${patterns[@]}"; do
      if rg --pcre2 --multiline --multiline-dotall --quiet "$pattern" "$file"; then
        used=true
        break
      fi
    done

    if $used; then
      echo "✅ Used"
    else
      echo "❌ Possibly unused"
    fi

  done <<< "$fields"

  echo
done


