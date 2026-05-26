---
alwaysApply: true
scene: git_message
---
Git提交信息生成规则
1. 格式: <type>(<scope>): <subject>
    - type: 变更类型 (feat, fix, docs, style, refactor, test, chore)
    - scope: 影响模块 (ui, api, db, config, utils, core, etc.)
    - subject: 简短描述（中文，不超过50字符）
 
2. 示例:
    - feat:(ui) 添加用户登录页面
    - fix:(api) 修复用户认证接口异常
    - docs:(readme) 更新项目部署说明
    - refactor:(core) 重构数据验证逻辑
 
3. 注意事项:
    - 使用现在时态
    - 首字母不大写
    - 末尾不加句号
 

