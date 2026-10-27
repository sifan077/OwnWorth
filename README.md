<p align="center">
  <img src="assets/branding/app_icon.png" width="96" alt="值回票价应用图标" />
</p>

# 值回票价 · OwnWorth

一个完全离线的个人物品成本追踪器。记录数码设备、衣物、家具、家电等耐用品的购入价格和使用日期，把一次性支出摊薄到每一天，看看它是否正在「值回票价」。也可以记录每次使用，查看单次使用成本。

- 不需要账号，不联网，不上传任何数据。
- 数据保存在本机 SQLite，图片保存在 App 私有目录。
- 支持日常搜索、分类、排序、目标日均成本、使用次数统计、结束使用和完整备份恢复。

## 功能

### 首页

- 在用物品数量、全部记录累计购买金额、在用物品「日均成本合计」。
- 「使用统计」在有使用记录时才显示全部物品的累计使用次数和本月使用次数。
- 物品卡片展示图片/分类占位图、名称、分类、购入价格、持有天数、当前日均成本和状态；有使用记录时额外标注累计使用次数，并在日均成本右侧以更小字号显示次均成本。
- 按名称搜索、按六个预设分类筛选。
- 按日均成本高低、购入日期新旧、使用次数多少排序。
- 点击进入详情，右下角添加物品。
- 空状态引导、加载状态、错误重试、下拉刷新。
- 数据库基于 Drift 响应式查询，增删改后自动刷新。

### 添加 / 编辑

- 图片（相册或拍照，可选）。
- 名称、价格、购买日期、分类、目标日均成本、备注。
- 校验必填项、金额、最多两位小数、购买日期不能晚于今天、结束日期规则。
- 图片在保存时复制到 App 私有目录，不依赖 `image_picker` 的临时路径。
- 更换或移除图片后清理旧文件。

### 详情

- 当前日均成本作为主视觉。
- 购入价格、已持有天数、购入日期。
- 使用统计：有使用记录时显示累计使用次数、单次使用成本、本月使用次数、最近使用日期；没有记录时整块隐藏，只保留「用一次」入口。
- 「用一次」按钮记录一次使用；可撤销最近一次记录。结束使用后不再允许新增记录。
- 目标日均成本、目标进度条、所需总天数、预计达成日期、剩余天数。
- 已结束但未达到目标时显示「未达成」，不再倒计时。
- 编辑、结束使用（选择结束日期）、重新启用、删除（二次确认）。
- 显示购买日期、结束日期和备注。

### 设置

- 浅色 / 深色 / 跟随系统，选择会持久化。
- 导出 ZIP 备份（版本化 JSON + 全部图片 + 使用记录）。
- 导入前完整校验、展示备份摘要、二次确认后全量恢复。
- 应用版本和说明。

## 技术栈

| 用途 | 方案 |
|---|---|
| 框架 | Flutter / Dart（当前稳定版） |
| UI | Material 3，自定义浅色/深色主题 |
| 状态管理 | Riverpod 3 |
| 路由 | GoRouter（底部 NavigationBar + 全屏编辑/详情页） |
| 数据库 | Drift + SQLite |
| 图片 | image_picker + path_provider |
| 本地图片路径 | 相对 App 数据目录保存 |
| 文件导入导出 | file_picker（系统文件选择器 / 保存器） |
| 备份压缩 | archive（ZIP） |
| 其他 | uuid、shared_preferences、package_info_plus、intl |

## 项目结构

```text
lib/
  main.dart                     # 初始化目录、数据库、SharedPreferences 后启动
  app/
    app.dart                    # MaterialApp.router、主题、生命周期刷新
    router.dart                 # GoRouter 路由
    app_shell.dart              # 底部导航壳
    theme/app_theme.dart        # Material 3 浅色/深色主题
  core/
    backup/backup_service.dart  # ZIP 备份、校验、恢复
    database/app_database.dart  # Drift 表与数据库
    database/app_database.g.dart
    storage/app_storage.dart    # App 私有目录
    storage/image_store.dart    # 图片保存、清理、原子替换
    utils/date_utils.dart       # 自然日工具
    utils/money.dart            # 整数分金额工具
    widgets/empty_state.dart
    providers.dart              # 基础 Riverpod provider
  features/
    items/
      data/item_repository.dart
      domain/owned_item.dart
      domain/usage_calculations.dart
      domain/item_usage.dart
      domain/cost_calculations.dart
      domain/item_query.dart
      presentation/home_page.dart
      presentation/item_form_page.dart
      presentation/item_detail_page.dart
      presentation/items_providers.dart
      presentation/widgets/
    settings/
      presentation/settings_page.dart
      presentation/theme_providers.dart
test/
  domain/                       # 日期、金额、成本、排序单元测试
  data/                         # Drift Repository、持久化测试
  core/                         # 图片存储、备份往返测试
  widget/                       # 首页空态、统计、搜索、自动刷新
```

## 数据模型

```text
OwnedItem
  id                   UUID
  name                 物品名称
  purchasePriceCents   购买价格（整数分）
  purchaseDate         购买日期（日期，不含时间）
  category             digital / appliance / home / clothing /
                       entertainment / other
  imagePath            相对路径 images/<file>，可为空
  targetDailyCostCents 目标日均成本（整数分），可为空
  status               ACTIVE / ENDED
  endDate              结束日期，可为空
  note                 备注，可为空
  createdAt            创建时间
  updatedAt            修改时间

ItemUsage
  id                   使用记录 UUID
  itemId               关联的物品 ID
  usedAt               使用时间（UTC 时刻）
```

所有金额以整数「分」存储，避免浮点误差。日期在数据库中存为严格的 `yyyy-MM-dd` 文本，读取后转为 UTC 日期容器；日期计算只使用年/月/日，不受时区、夏令时或当前时分秒影响。使用记录单独存放在 `item_usages` 表，数据库从版本 1 升级时会自动建表，原有物品数据不受影响。

## 计算规则

```text
有效结束日期 = ACTIVE ? 今天 : endDate
持有天数 = 日历日差(有效结束日期, 购买日期) + 1
日均成本 = 购买价格 / 持有天数

目标所需总天数 = ceil(购买价格 / 目标日均成本)
目标达成日期 = 购买日期 + 所需总天数 - 1 天
剩余天数 = max(0, 所需总天数 - 持有天数)
目标进度 = min(100%, 持有天数 / 所需总天数)

单次使用成本 = 购买价格 / 累计使用次数
本月使用次数 = 使用时间换算为本地时间后，落在当前自然月的记录数
```

- 购买当天记为第 1 天。
- 使用记录保存完整 UTC 时刻，首页和详情页按月统计时先转换为设备本地时间。
- 单次使用成本在没有使用记录时不显示（整块使用统计隐藏），也不参与日均成本计算。
- 结束使用的物品保留全部历史记录，但不能继续新增使用记录。
- 目标所需天数使用整数运算，不经过浮点。
- 日均成本显示保留两位小数，内部保留小数精度。
- 已结束物品的持有天数、日均成本、目标进度都固定在结束日期。
- 首页「日均成本合计」只累加 `ACTIVE` 物品，是把购入成本摊薄后的结果，不代表每天实际支出。
- 所有指标在读取时动态计算，不随日期写入数据库；App 从后台恢复或跨过午夜后会重新计算。

## 备份格式

备份是 ZIP 文件，内部结构：

```text
manifest.json
images/<uuid>.jpg
images/<uuid>.png
...
```

`manifest.json` 为版本化数据：

```json
{
  "format": "ownworth-backup",
  "formatVersion": 2,
  "appVersion": "1.0.0 (1)",
  "exportedAt": "2026-10-25T10:30:00.000Z",
  "itemCount": 2,
  "imageCount": 1,
  "usageCount": 3,
  "items": [
    {
      "id": "...",
      "name": "...",
      "purchasePriceCents": 499999,
      "purchaseDate": "2025-03-18",
      "category": "digital",
      "imagePath": "images/....jpg",
      "targetDailyCostCents": 500,
      "status": "ACTIVE",
      "endDate": null,
      "note": "...",
      "createdAt": "...",
      "updatedAt": "..."
    }
  ],
  "usages": [
    {
      "id": "...",
      "itemId": "...",
      "usedAt": "2026-10-20T12:00:00.000Z"
    }
  ]
}
```

导入 `formatVersion` 1 的旧备份时按「没有使用记录」处理，导出始终使用版本 2。

导入时的保护：

- 限制 ZIP、单张图片、总图片和记录数量的大小。
- 校验 ZIP 条目、清单 JSON、格式版本、CRC32、图片存在性和引用一致性。
- 路径必须是 `images/<安全文件名>`，拒绝目录穿越、未知条目和重复引用。
- 校验日期、金额、状态、结束日期和分类。
- 校验使用记录的时间、所属物品和 ID 唯一性，拒绝孤立记录。
- 校验失败不会触碰现有数据。
- 校验通过后，图片目录替换与数据库全量替换一起执行；数据库事务失败会回滚旧图片目录。
- 导入为全量覆盖，不合并记录。

## 运行

环境要求：

- Flutter 3.47 或更新的稳定版（项目实际验证版本：Flutter 3.47.8 / Dart 3.13.7）
- Android SDK、JDK 17+
- Android 设备或模拟器（最低 API 24）
- iOS 15+（代码兼容，需在 macOS + Xcode 环境构建）

命令：

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

Debug APK 输出：

```text
build/app/outputs/flutter-apk/app-debug.apk
```

首次构建 Android 时，`package:sqlite3` 的 native assets 需要下载官方预编译 SQLite 动态库。如果网络需要代理，请在执行构建的终端中设置：

```powershell
$env:HTTP_PROXY = 'http://127.0.0.1:7890'
$env:HTTPS_PROXY = 'http://127.0.0.1:7890'
flutter build apk --debug
```

### 数据库代码生成

Drift 表结构改动后运行：

```bash
dart run build_runner build
```

### Android / iOS 配置

- Android applicationId / namespace：`com.ownworth.app`
- Android 显示名称：值回票价
- iOS Bundle ID：`com.ownworth.app`，Deployment Target 15.0
- iOS 已配置 `NSPhotoLibraryUsageDescription`、`NSCameraUsageDescription`
- 图片选择使用系统选择器或相机；备份导入导出使用系统文件选择器，不申请无关存储权限。
- 项目移除了 Web/Windows/Linux 平台壳，保留 Android 和 iOS；这是移动端优先的个人工具项目。

## 测试

```text
flutter test
```

测试覆盖：

- 今天购买持有 1 天；10 天前购买按自然日计算。
- 跨月、跨年、闰年 2 月 29 日。
- 小数金额解析、整数分存储、金额格式化和显示舍入。
- 目标刚好达成、超过目标、目标极小。
- 使用次数、本月使用次数、单次使用成本和最近使用时间。
- 已结束物品的日均成本不再降低，未达成目标固定显示。
- 编辑价格/日期后统计重算、删除后列表与统计同步更新。
- 删除物品时级联清理使用记录。
- 关闭并重新打开数据库后数据仍然存在。
- 备份导出/导入后记录、状态、日期、目标、使用记录和图片保持一致。
- 旧版（formatVersion 1）备份可以导入，并按无使用记录处理。
- 损坏 ZIP、缺失图片、未知备份版本、非法日期和孤立使用记录会被拒绝且不覆盖现有数据。
- 图片目录替换在数据库提交失败时回滚。
- 首页空状态、统计展示、搜索筛选、数据库变更自动刷新。
- 表单完整渲染与滚动；详情页目标进度、使用记录新增/撤销、结束使用、重新启用。

最终一次完整测试：**70 项全部通过**。

## 构建与运行验证

在本开发环境实际执行结果：

```text
flutter pub get          通过
dart format .            通过
flutter analyze          No issues found
flutter test             70 tests passed
flutter build apk --debug 成功
```

Debug APK：

```text
build/app/outputs/flutter-apk/app-debug.apk
```

另外在 Android 17（API 37）x86_64 模拟器上完成安装和启动，实际验证了：

- 首页空状态、概览统计、物品卡片和数据库响应式刷新。
- 使用统计概览、详情页「用一次」、撤销最近一次记录，以及在 360dp 窄屏下的布局。
- 添加物品（名称、金额、分类）、保存后首页统计与列表立即更新。
- 详情页的日均成本、目标区域和元信息展示。
- 设置页、浅色/深色主题切换与持久化。
- 重启 App 后本地数据仍存在。

搜索、筛选、排序、表单滚动、结束使用/重新启用等其余交互由 Widget / 单元测试覆盖。

iOS 代码、权限声明和图标已配置，但当前 Windows 开发机没有 Xcode，未执行 iOS 构建。

## 已实现与未实现

已实现：

- 四个页面：首页、添加/编辑、详情、设置。
- 完整 CRUD、搜索、分类筛选、排序。
- 日均成本、目标进度、结束/重新启用。
- 使用记录、累计/本月使用次数、单次使用成本、撤销最近一次记录。
- Drift 本地数据库、相对路径图片存储、孤立图片清理。
- ZIP 备份导入导出、完整性校验、事务恢复。
- 浅色/深色/跟随系统主题。
- 单元测试、数据库测试、备份测试、Widget 测试。
- Android Debug APK 实际构建成功。

第一版明确不做：

- 登录、云同步、多用户。
- AI 或图片识别。
- 订单自动导入、多币种。
- 二手残值、折旧、维修费用。
- 订阅/周期性支出、推送通知。
- 复杂统计图表、使用趋势分析、社区/社交。

## 隐私

应用没有后端和账号系统，也不调用任何 AI/远程接口。物品数据、图片和备份全部保存在本机；导出文件只会在用户主动选择保存位置时写入。
