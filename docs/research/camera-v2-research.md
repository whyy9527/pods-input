# Camera V2 — Tilt Rush 摄像头头部追踪研究文档

> 基于 2026-07-11 Codex 会话 `rollout-2026-07-11T13-05-01-019f4f90` 提取

---

## 目录

1. [背景：从 AirPods 到摄像头的路线变更](#1-背景从-airpods-到摄像头的路线变更)
2. [核心实现方案](#2-核心实现方案)
3. [首次测试：摄像头权限问题](#3-首次测试摄像头权限问题)
4. [校准 UI 反馈与改进](#4-校准-ui-反馈与改进)
5. [校准体验社区调研](#5-校准体验社区调研)
6. [HUD 升级与 Forza Horizon 5 参考](#6-hud-升级与-forza-horizon-5-参考)
7. [V2 决策：不做 AirPods 集成](#7-v2-决策不做-airpods-集成)
8. [第一人称视角提案](#8-第一人称视角提案)
9. [技术要点总结](#9-技术要点总结)

---

## 1. 背景：从 AirPods 到摄像头的路线变更

### 初始架构

在摄像头方案之前，Tilt Rush 的设计围绕 **AirPods 头部运动 + macOS 原生 App + Chrome Extension** 这一链路展开：

```
AirPods → PodsInput macOS App → Chrome/Edge Extension（Native Messaging）→ Tilt Rush iframe
```

Agent 最初认为这是唯一可行的方案，因为浏览器不能直接读取 AirPods 头部运动——Apple 只通过原生 Core Motion 的 `CMHeadphoneMotionManager` 提供数据。

### 用户质疑：游戏太无聊

用户回应：

> "那这个游戏就很无聊了啊。能要视频权限吗？"

Agent 随即评估了摄像头方案的可行性，结论是：

> 可以，而且这比要求玩家安装 macOS App 更适合公开网页游戏：浏览器请求摄像头权限，在本机做人脸关键点识别，用歪头控制转向、抬头触发跳跃，不上传视频，也不需要云端服务。

### 新方案链路

```
Camera → getUserMedia() → MediaPipe Face Landmarker / WASM → 计算头部 roll 和 pitch → Tilt Rush
```

核心优势：
- 全浏览器端运行，无需安装任何软件
- 视频不上传、不需要后端
- 兼容 Mac、Windows、Chromebook 甚至手机
- AirPods 保留为更精准的高级输入方式（后续）

---

## 2. 核心实现方案

### 控制映射

| 头部动作 | 游戏控制 |
|---------|---------|
| 左右歪头 (roll) | 转向 |
| 快速向上抬头 (pitch) | 跳跃 |
| 正视屏幕 1 秒 | 自动校准中心 |
| 摄像头不可用 | 键盘 fallback |

### 技术实现细节

- **人脸关键点识别**: MediaPipe Face Landmarker (WASM + CPU 推理)
- **帧率**: 每秒 ~15 帧识别，不必跑满摄像头帧率
- **死区**: 3° 左右防止自然晃动
- **跳跃检测**: 短时间 pitch 变化，避免绝对姿势漂移
- **丢失人脸处理**: 连续丢失时暂停转向，防止摩托继续偏向一侧

### iframe 权限变更

MarsLadder 当前 iframe 权限：

```tsx
allow="autoplay; fullscreen; gamepad"
```

需要改为：

```tsx
allow="autoplay; fullscreen; gamepad; camera"
```

跨域 iframe 只有得到顶层页面授权后才能弹出摄像头权限。

### 用户交互流程设计

1. 开始页显示 `Enable camera controls`
2. 用户主动点击后申请摄像头权限
3. 显示明确说明：`Video stays on this device and is never uploaded.`
4. 检测到脸后中心校准
5. 摄像头运行时显示小型状态指示（不显示自拍画面）
6. 离开页面立即停止摄像头
7. 权限拒绝或无脸检测时自动切换键盘

---

## 3. 首次测试：摄像头权限问题

### 问题现象

用户报告：

> "给了摄像头权限一会就退出了"

### 根因分析

Agent 检查发现：

| 资源 | 状态 | 说明 |
|------|------|------|
| `@mediapipe/tasks-vision@0.10.22/+esm` | **404** | JS 入口文件不存在 |
| `@mediapipe/tasks-vision@0.10.22/wasm/...` | **404** | WASM 文件不存在 |
| `face_landmarker.task` 模型 | **200** ✅ | 模型正常 |

使用了不存在的 MediaPipe 版本 (`0.10.22`)，导致授权后模型加载 404，摄像头随即被 `catch` 停掉。

### 修复

```diff
- @mediapipe/tasks-vision@0.10.22
+ @mediapipe/tasks-vision@0.10.35 (已验证可用)
- delegate: 'GPU'
+ delegate: 'CPU' (兼容性更高)
```

Agent 结论：

> 根因已修复：MediaPipe 版本地址不存在，导致授权后模型加载 404，摄像头随即停止。

---

## 4. 校准 UI 反馈与改进

### 用户反馈 1：校准提示不明显

> "可以，就是 Look straight at the camera 不是很明显，能否 enable 的校准的时候做一个绿模展示，校准完成之后再关闭这样体验更好？或者更简单的校准弹窗？"

### Agent 方案：校准弹窗

Agent 选择了"校准弹窗"方案，取代简单的文本提示：

**弹窗内容**：
- 镜像摄像头画面（mirrored preview）
- 绿色脸部轮廓框（face guide）
- 双眼定位点
- 校准进度条
- "Look straight ahead" 提示
- 校准完成后自动淡出关闭
- 点击 `Center` 可重新校准

**CSS 实现**：
```css
.camera-calibration {
  position: fixed; z-index: 5; inset: 0;
  display: grid; place-items: center;
  background: #02050dcc; backdrop-filter: blur(10px);
}
.calibration-card {
  width: min(380px, calc(100vw - 40px));
  border: 1px solid #66ffb680;
  border-radius: 22px;
  background: #07130fee;
}
.face-guide {
  border: 3px solid #55f59c;
  border-radius: 48% 48% 44% 44%;
  box-shadow: 0 0 22px #55f59c99;
}
```

### 用户反馈 2：进度条真实性

> "进度条现在是按时间吗？不是校准时的真进度条吗？你去社区上搜一下到底什么校准体验好"

### 自我修正

Agent 承认：

> 现在这条不是纯时间条，但也不够"真"：它按成功检测到的 18 帧累加，只要检测到脸就推进，没有判断脸是否居中、是否稳定。

---

## 5. 校准体验社区调研

Agent 搜索了 Reddit、GitHub 和 HN 上的头部追踪社区，发现：

### 社区共识

> "头部中立位校准"不需要眼动仪那种多点标定，核心是让用户舒服地看正前方，并且随时可以重新居中。真正影响体验的是 **检测质量、稳定性、明确提示和一键重置**，而不是把动画播完。

重要发现来源：
- **OpenTrack** (GitHub Wiki): 依赖固定中心校准 + 死区配置 + 一键重置
- **Apple Eye Tracking**: 校准自动在需要时重新触发
- **TrackIR 社区**: 用户最在意"一键回到中心"而不是多点标注

### 改进方案

Agent 决定改为两阶段校准：

1. **对齐阶段**: 检查脸部位置和大小是否合格
2. **稳定阶段**: 只有位置和大小合格后，稳定保持的数据才推进进度
   - 移动 → 暂停并提示
   - 丢脸 → 暂停并提示
   - 过近/过远 → 暂停并提示

---

## 6. HUD 升级与 Forza Horizon 5 参考

用户提出：

> "怎么实现赛场游戏那种感觉，你知道极速地平线 5 不？左上角和右上角的 UI 应该升级，太简陋了。"

Agent 研究 FH5 的 HUD 设计后：

> FH5 的"赛场感"并不是把 HUD 塞满，而是用很强的信息层级制造赛事直播感

### HUD 改造

| 区域 | 内容 |
|------|------|
| **左上** (赛事信息) | 比赛编号、关卡名称、实时完成度、进度条、输入状态、控制切换 |
| **右上** (速度仪表) | 大号实时速度、档位、动态转速带、当前分数、最高分、车辆完整度 |
| **中央** | 保持干净，遮挡赛道 |

视觉风格沿用 Tilt Rush 的黑红能量主题，不照搬 Forza 设计。

---

## 7. V2 决策：不做 AirPods 集成

### 关键对话

用户 (ts=1783786618, 14:56 CST):

> "要开新 v2 复用素材还是直接重构？"

用户 (ts=1783787331, 15:08 CST):

> "V2 不做 airpods 集成了。开始吧"

### 解读

- **V2 作为一个独立版本**：决定以摄像头为主要输入方式重新定位 Tilt Rush
- **取消 AirPods 集成**：简化发布流程，不需要用户安装 macOS App 和 Chrome 扩展
- **复用已有素材**：Tilt Rush 的游戏逻辑、赛道设计和视觉资产继续使用
- **"开始吧"**: 正式启动 V2 开发

### 决策后的工作

V2 决策后，Agent 继续迭代了：
1. 赛道视觉与关卡设计（四章教学关卡，独立弯道节奏）
2. 主菜单生成了 AI 艺术资产
3. HUD 升级为 FH5 风格的赛事 HUD
4. 校准体验改进

---

## 8. 第一人称视角提案

用户提出能否有第一人称视角，Agent 将其视为**独立提案**而非当前可做功能：

### 所需工作

1. 透视赛道渲染器（道路曲线 → 地平线与消失点）
2. 驾驶舱镜头（车把、挡风罩、悬挂运动）
3. 歪头压弯 + 抬头跳跃
4. 前车提前在地平线出现
5. 弯道路标/导航线/副驾驶提示
6. 跳跃镜头晃动控制（避免眩晕）

Agent 强调：

> 第一人称完全可以做，但我建议把它视为新模式，而不是当前游戏的视角按钮

---

## 9. 技术要点总结

### 关键决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 输入方式 | 摄像头头部追踪 | 无需安装，跨平台，隐私安全 |
| 人脸识别库 | MediaPipe Face Landmarker (WASM + CPU) | 浏览器本地运行 |
| 校准 UI | 弹窗（镜像画面 + 绿框 + 进度条） | 用户反馈驱动 |
| AirPods | V2 不做集成 | 简化发布流程 |
| First-person | 独立提案，不塞入 V2 | 架构变更大 |

### 待解决问题

- 校准进度条需要改为"对齐 → 稳定保持 → 推进"的真质量门槛
- MediaPipe CDN 版本需要持续验证可用性
- MarsLadder iframe 权限需要增加 `camera` 权限
- 第一人称需要独立的透视渲染管线（不是当前俯视的视角切换）
