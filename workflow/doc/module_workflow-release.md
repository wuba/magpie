# workflow 发包

| 时间         | 说明        | 修改人  |
| ---------- | --------- | --------  |
|  2019.12.24     | 添加workflow产物和启动流程       | 吴朝彬     |

## 模块设计

workflow包含web+server，以压缩包形式提供给cli启动。相关逻辑如下：

### 打包workflow
打包workflow，并归档于cli下

> ./deploy -cli

内部操作：
1. 构建flutter web
2. 打包server，web资源形成压缩包；
3. 归档压缩包值cli/packages目录

### 本地验证
如果需要本地验证脚手架和workflow的流程
> ./setup_cli

内部操作：
1. 将cli部署本地；
2. 验证cli能力能力，如启动workflow

