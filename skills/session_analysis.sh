#!/bin/bash
# session_analysis - Analyze a therapy session transcript
INPUT=$(cat)
echo "{\"result\": \"ok\", \"skill\": \"session_analysis\", \"input\": $INPUT}"
