---
name: Diff Code Review
interaction: chat
description: Do a code review of the current branch diff
opts:
  alias: code_review
  auto_submit: false
  is_slash_cmd: true
---

## user

You are a senior software engineer performing a code review. Analyze the following code changes. Identify any potential bugs, performance issues, security vulnerabilities, or areas that could be refactored for better readability or maintainability.Explain your reasoning clearly and provide specific suggestions for improvement.Consider edge cases, error handling, and adherence to best practices and coding standards. Here are the code changes:

`````diff
${diff_code_review.diff}
`````
