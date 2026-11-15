# Art Bible: Lonefire（孤火）

> **Status**: Approved (provisional — owner delegated: "大胆往前走")
> **Owned By**: art-director
> **Last Updated**: 2026-11-15
> **Art Director Sign-Off (AD-ART-BIBLE)**: AD-ART-BIBLE skipped — Solo mode

`/art-bible` writes these nine sections in this order and replaces each
section's `[To be designed]` line as that section is approved. A section still
holding its placeholder is incomplete; a later run fills only those.

Evidence for every number here: `prototypes/lookdev/` (day = baseline, `-- --preset dusk`).

## 1. Visual Identity Statement

**一句话规则：整个世界是冷的，只有活下去的东西是暖的。**（Everything is cold except what keeps you alive.）

- **暖色是稀缺资源**（支柱：冷与暖）。暖色（warm_orange / ember_yellow / brick_red / skin_warm）只给火、庇护所篷布、人物身上。*测试：一个新物体该用什么色拿不准时，问"它让人更暖或更安全吗？"——不是就用冷色。*
- **大块面，少细节**（支柱：慢压力、独处）。远景读的是色块和长投影，不是纹理。*测试：一个细节在游戏镜头下小于约 8 像素就删掉，或并进相邻色块。*
- **人造物都是临时的**（支柱：亲手做）。玩家做出来的东西看起来是手搭的：歪的木杆、绑起来的篷布、堆起来的石头，从不规整。*测试：在"整齐"和"手工"之间拿不准时，选手工。*

## 2. Mood & Atmosphere

| 状态 | 情绪 | 光照 | 形容词 | 节奏 | 承载元素 |
|---|---|---|---|---|---|
| 白天外出（基准） | 清醒、开阔、有点孤单 | 低角度暖白太阳（`#FFF3D0`，1.5，仰角 22°）+ 浅冷环境光（`#E7EBF3`，1.3）；中低对比 | 明亮、安静、干净、辽阔 | 从容 | 蓝色长投影 |
| 黄昏 / 夜晚回营 | 紧迫转为安心 | 太阳几乎熄灭（`#FFA764`，0.08）；深蓝环境光（`(0.02,0.10,0.26)`，1.6）；火光是唯一暖光，半径约 6 m | 寒冷、深沉、收拢、温暖的中心 | 收敛 | 火光照亮的那一圈雪 |
| 暴雪 / 寒潮 | 压迫、看不远 | 平光，几乎无投影；雾拉近到 30–40 m；整体去饱和 | 灰白、模糊、刺骨、单调 | 焦虑 | 消失的远景 |
| 失温危险 | 恐慌 | 画面边缘向 trunk_navy 收暗、去饱和；暖色不受影响 | 收窄、发蓝、迟钝 | 急促 | 视野边缘的暗角 |
| 死亡 / 撤离 | 沉重、平静 | 定格后慢慢褪成雪白 | 空、静、白 | 停止 | 雪覆盖营地 |
| 主动退赛 | 释然 | 拉远航拍；黄昏暖光 | 远、轻、回望 | 舒缓 | 远处的一点火光 |
| 菜单 / 日记 | 内省 | 屏幕空间，纸面暖白 | 私密、手写、安静 | 静止 | 手写日记页 |

## 3. Shape Language

- **人物**：矮胖、圆头兜帽、背包凸起；在约 50° 俯角远镜头下靠"深色剪影 + 橙色领口"识别，不靠脸。
- **自然物**：针叶树是堆叠的尖锥三层；枯树是粗短折线；石头是钝多面体；雪地是缓坡大平面。尖锥和折线 = 冷、不友好。
- **营地物**：A 字形与三角（篷布、木杆、柴堆的锥形）——和松树同是三角，但更矮、更歪，读作"人搭的"。
- **主次**：主角形状是火堆和篷布（唯一的暖色 + 三角）；松林是中景框架；雪地和投影退后做背景。
- **UI**：见第 7 节（待定）；原则上用纸面和手写，不模仿世界里的低模。

## 4. Color System

调色板源：`tools/assets/palette.json`。每个资产在 `prototypes/lookdev/assets.json` 里只允许用其中 2–5 色。

| 颜色 | Hex | 角色与含义 |
|---|---|---|
| snow_light | `#EAF2FB` | 地面主色、积雪；画面 60–70% |
| snow_shadow | `#B9D0EA` | 投影、背光雪；冷的"安静" |
| pine_dark / pine_mid | `#2F4B5C` / `#3F6274` | 林木主体；冷的生命 |
| trunk_navy | `#1E2A44` | 最暗值：树干、枯树、夜色方向 |
| roof_slate | `#3B4A63` | 人物外套；人造但冷 |
| stone_gray | `#8C97A8` | 石头、石圈 |
| wood_brown | `#6B4A3A` | 木头、背包、靴子；中性的"可用材料" |
| brick_red | `#B5503F` | 庇护所篷布；"家"，不发光的暖 |
| warm_orange | `#F08A4B` | 火焰外层、人物领口；"热量与生命" |
| ember_yellow | `#FFC66B` | 火焰核心；全游戏最亮的暖色，只给火 |
| skin_warm | `#E8B894` | 脸和手，仅人物 |

- **语义**：暖 = 安全 / 热量；蓝 = 寒冷 / 危险的程度；白 = 中性与空。没有绿色语义（世界里没有草）。
- **配额**：白天远景中暖色面积 ≤ 5%；火是唯一自发光物体。
- **区域温度**：湖面比林地更冷（往 snow_shadow 偏）；营地 6 m 内在夜里被火光染暖。
- **UI 色板**：纸面暖白与墨色为底；状态色复用世界语义（体温冷 = 蓝，暖 = 橙）。
- **色盲安全**：
  - brick_red 篷布 vs wood_brown 木头（红/棕）：靠形状区分（篷布是大平面，木头是细杆）。
  - warm_orange 火 vs brick_red 篷布：火会发光、闪动、投光，篷布不会。
  - 体温条蓝/橙：蓝橙对红绿色盲安全；另加图标（雪花 / 火苗）和填充方向作备用。
  - 不使用红/绿对来表达任何状态。

## 5. Character Design Direction

- **玩家**：唯一角色。厚外套（roof_slate）、兜帽、背包与靴子（wood_brown）、橙色领口（warm_orange，规则见 assets.json `rules`）。
- **识别**：远镜头下人物只有约 20–40 像素高，靠剪影和橙色识别；橙色必须在白天远景截图里可见（证据：`prototypes/lookdev/evidence/survivor_wide_crop.png`）。
- **动物**：鱼、野兔、松鸡活着时只用冷色或中性色（兔白灰、松鸡棕灰），不用暖色；做成熟食后才可以带暖色（它这时才是"让人活下去的东西"）。
- **动作风格**：慢、重、费力；肢体动作要大，远镜头下才读得出（砍、蹲、搓手）。不做表情动画。
- **LOD**：游戏镜头下不需要脸部细节；人物一档 LOD 即可。

## 6. Environment Design Language

- **没有建筑**：只有手搭的东西（A 字篷布、斜棚、石圈、柴堆）。不做小屋和永久结构。
- **表面**：无贴图，每面一色；明暗全靠光照与投影。AI 模型贴图只用来取色，之后丢弃。
- **密度**：空地留大片空白雪地（孤独感）；树木成团出现，团与团之间留空；营地道具集中在火堆 6 m 内。
- **无文字叙事**：脚印、熄灭的灰、被雪埋了一半的工具，说明时间过去了多少。

## 7. UI/HUD Visual Direction

[To be designed] — 推迟到 `/ux-design` 阶段（手感原型之后）。约束先记下：纸面 + 手写日记风格；体温状态最醒目；全部文字走翻译表；按钮按手指尺寸。

## 8. Asset Standards

**美术侧**
- 格式：GLB（glTF 2.0），Y-up，原点在底面中心，单位米；颜色存 `COLOR_0` 顶点色，无贴图、无图片。
- 命名：`[category]_[name]_[variant].glb`，如 `env_pine_a.glb`、`prop_campfire_a.glb`、`char_survivor_a.glb`。（现有 lookdev 资产仍用 `<name>_flat.glb`，进入正式项目时改名。）
- 生产链：qwen-image 概念图 → 审图 → 混元 3D 3.0 LowPoly → `tools/assets/flatten_glb.py`（逐面配色、加权 Oklab、邻面平滑、几何颜色规则、`max_tris`）→ `inspect_glb.py` → Godot 截图审查。
- 简单形状（原木、木柴、木杆、冰洞、雪堆、脚印、火焰、烟）用脚本直接建模，不花积分。手持小工具只做 2D 图标。

**技术侧**
- 引擎 Godot 4.7，Forward+；60 fps / 16.6 ms（`project.yaml`）。Draw call 与内存预算未设定（待目标硬件确定）。
- 三角面：一般道具与环境 ≤ 3000；人物与庇护所当前为 3222 / 4195，超出 PLAN.md 的 3000 上限。理想标准是全部 ≤ 3000；受限标准是给这两个主角资产放宽到 ≤ 4500。取舍：减面会损失篷布褶皱和人物轮廓，二者都在画面焦点上。**待负责人决定**，未决前按受限标准。
- 材质：每个资产 1 个材质（顶点色 × 白色基色，roughness 1，metallic 0）；同材质资产可合批。
- 植被：树木和石头用 MultiMesh 实例化。
- 未验证项：Godot 4.7 对顶点色 GLB 的合批行为、Mobile 渲染器下的投影效果（引擎参考文档未覆盖）。

## 9. Reference Direction

| 参考 | 取什么 | 避免什么 |
|---|---|---|
| 用户提供的 B 站 Godot 雪地视频（BV1Pwbi6SE3i） | 高位远镜头构图、纯色块、冷雪暖点 | 小屋与烟囱（本作没有建筑） |
| 《荒野独居》节目 | 日记镜头的私密感、"还剩几人"的压力 | 写实影像质感 |
| 《Firewatch》 | 大面积单色区块和每个时段一套完整配色 | 它的暖橙主调（本作以冷为主） |
| 《The Long Dark》 | 室外刺骨、火边安心的温度对比；暴雪吞掉远景 | 手绘笔触贴图 |
| 《A Short Hike》 | 远镜头下小人物的可读性 | 低分辨率像素化效果 |
