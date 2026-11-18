# Game Concept: Lonefire（孤火）

*Created: 2026-11-16*
*Status: Draft*

> Source: `design/game-brief.md` (owner quotes, kept verbatim there) + `prototypes/firebeforedark-concept/REPORT.md` (2026-11-15 PIVOT) + `/brainstorm` 2026-11-16. Concept chosen by owner: Concept 1 "The Long Cold" as the core, plus "Day N"'s self-filmed episode and show-camera view, plus "Small Warm"'s own camp.

---

## Elevator Pitch

> 一个人被丢进北方雪原：一局一局地学会这片荒野——柴怎么烧、风怎么吹、身体和心在哪里会垮；你拍下自己的一季，并决定什么时候退赛。活着的时候很苦，回看的时候很美。
>
> *A winter survival sim where you learn the wild run by run, film your own season, and choose when to tap out — hard to live through, beautiful to look back on.*

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | 单人生存模拟（无战斗）· 一局制（run-based）· 知识型精通 |
| **Platform** | PC：macOS + Windows 首发；之后可能移动端（提前考虑多平台） |
| **Target Audience** | 见 Target Player Profile |
| **Player Count** | Single-player |
| **Session Length** | 45–90 分钟（约 2–3 个游戏日）；一局一季，数小时，夜间自动存档 *(provisional)* |
| **Monetization** | Premium（买断） |
| **Estimated Scope** | Large (8–10 months, solo with AI agents) — 比 owner 说的"几个月"长，见 Scope Risks |
| **Comparable Titles** | *The Long Dark*；《荒野独居》（*Alone*，电视节目）；*Firewatch*（孤独的语气）— sales not researched |

---

## Core Fantasy

我在荒野里一个人活了下来——不是靠变强，而是因为我越来越懂它。游戏之余，玩家能真的体验到野外独居的感受：冷是真的，饿是慢慢来的，孤独在第几天突然压下来；而火燃起来、日记拍完、一季剪成片的那一刻，又是平静而美的。

---

## Unique Hook

像《荒野独居》，**而且你既是选手也是镜头**：当下是冷、饿、失败的身体经验；夜里你对着镜头拍日记；一局结束，你拍下的东西剪成你自己的一集。高位远镜头就是节目组的机位——"参加很苦，观看很美"同时成立。

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Challenge** (obstacle course, mastery) | 1 | 真实的寒冷、体重流失、会失败的动作；精通靠知识（地图、天气、身体、心态） |
| **Sensation** (sensory pleasure) | 2 | 扁平低模雪原、长投影、火是唯一暖色；踩雪声、风、火的噼啪；沉重的身体动作 |
| **Narrative** (drama, story arc) | 3 | 玩家自己的一季：日记、失败与小胜、退赛或撑到底的结局、剪成的一集 |
| **Expression** (self-expression, creativity) | 3 | 亲手搭的营地；10 件装备的选择；日记里说什么 |
| **Discovery** (exploration, secrets) | 5 | 理解系统：干柴在哪、湖哪里有鱼、风从哪来；解锁新地点与季节 |
| **Submission** (relaxation, comfort zone) | 6 | 只在"观看"层：慢仪式时刻、火边、回看日记与成片 |
| **Fantasy** (make-believe, role-playing) | 7 | 成为荒野独居的参赛者 |
| **Fellowship** (social connection) | N/A | 单人；对手是模拟的 |

### Key Dynamics (Emergent player behaviors)

- 玩家出门前会抬头看天、看体温和体重，再决定走多远——而不是机械地清空地图。
- 玩家会为了好柴、为了鱼，冒险去更冷更远的地方，并为此付出代价。
- 失败之后玩家会去找原因（湿柴、风口、手冻僵了），下一次改做法。
- 玩家会在"还剩几人"和自己的状态之间反复权衡退赛。
- 玩家会愿意对着镜头说话，并回看自己的日记。

### Core Mechanics (Systems we build)

1. 沉重的身体与雪地：真实的地形和深雪、会陷入的脚步、需要多次挥动的动作，动作有时长、有动画、会被打断。
2. 会失败的生存动作：生火、劈柴、钓鱼、设陷阱都有可读原因的失败（湿、风、疲劳、手冷、心态）。
3. 身体与心态：体温、水分、体力、饱腹、体重，加上心态维度（孤独、挫败（含无力与失望）、伤心、饥饿感、痛苦；权威定义见 Morale & Mental State GDD）——心态是推人退赛的力量。
4. 退赛赌注：模拟对手陆续退赛、名次、医疗检查，在撑下去和现在走之间下注。
5. 拍摄与回看：夜间自拍日记，局末剪成一集；解锁的东西以纪念与故事出现。

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | 去哪、带哪 10 件、营地怎么搭、什么时候退赛 | Core |
| **Competence** (mastery, skill growth) | 每局更懂荒野；失败有可读原因，下次能做对 | Core |
| **Relatedness** (connection, belonging) | 和自己：日记、纪念物；对手的存在让孤独有参照 | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** (goal completion, collection, progression) — How: 撑过的天数、退赛名次、解锁的地点/季节/纪念物
- [x] **Explorers** (discovery, understanding systems, finding secrets) — How: 主要人群；理解寒冷、柴火、天气、身体与心态如何相互作用
- [ ] **Socializers** (relationships, cooperation, community) — How: 不服务（可能分享成片，Full Vision 以后）
- [ ] **Killers/Competitors** (domination, PvP, leaderboards) — How: 不服务；排名只对模拟对手

### Flow State Design

- **Onboarding curve**: 第一天只有一行提示"天黑前要有火"；第一夜就冷，失败教会玩家火和身体的关系。
- **Difficulty scaling**: 一局内逐日变冷、资源变远、寒潮出现；跨局靠玩家自己的知识增长，后续可解锁更难的季节。
- **Feedback clarity**: 失败说出原因（画面与声音先于文字）；日记与成片让玩家看到自己比上一局撑得更久、做得更好。
- **Recovery from failure**: 死亡惩罚是失去本局大部分奖励，不是剥夺知识；新一局几分钟内落地。

---

## Core Loop

### Moment-to-Moment (30 seconds)

在深雪里蹚着走、劈一根要挥好几下的木头、划火——每个动作都费力（Heavy, effortful），而且可能失败，失败有可读原因：湿、风、手冷、累。满足感来自"费了劲终于成了"。其间夹着慢仪式时刻（Slow, ritual-like）：火燃起、伸手烤火、镜头慢慢拉远。

### Short-Term (5-15 minutes)

一次外出与回营：看天看身体，决定走多远——干柴在更远处、湖边有鱼但更冷——在身体或天光耗尽前回来。

### Session-Level (30-120 minutes)

约 2–3 个游戏日：白天外出（砍柴、找水、设陷阱、冰钓），天黑回营（添柴、吃、睡、拍日记、看还剩几人）。每一夜是天然的停止点和自动存档；理由回来：明天更冷，以及"还撑不撑"。

### Long-Term Progression

一局 = 一季（数小时）。结局：死亡、医疗撤离、主动退赛或撑满目标天数；拍下的素材剪成这一季的成片。跨局带走的只有：玩家自己的知识，和以纪念/故事形式解锁的特殊装备、地点、季节、地图——它们主要给情绪上的安抚与稳定，而不是实质性的生存加成。

### Retention Hooks

- **Curiosity**: 新地点、新季节、上一局没去过的湖岸；对手还剩几人
- **Investment**: 进行中的一季、自己搭的营地、日记与纪念物
- **Social**: 无（成片分享属于以后）
- **Mastery**: 撑得更久、退赛名次更高、用更少的失败过第一夜

---

## Game Pillars

### Pillar 1: 冷是真的（The Cold Is Real）
每个动作都花身体的代价，寒冷会咬人，失败与死亡是真的。

*Design test*: 宽容和惩罚之间拿不准时，选玩家能在"身体上"感到的那个——但原因必须可读。

### Pillar 2: 越活越懂（Know More Each Run）
成长的是玩家对荒野的理解，不是角色数值。

*Design test*: 一个解锁要么让生存更容易、要么成为一段纪念时，让它成为纪念。

### Pillar 3: 退赛是赌注（Tapping Out Is the Bet）
留下还是离开，始终是一个有真实代价的开放问题。

*Design test*: 一条信息会消除不确定性（比如对手的准确状态）时，不给。

### Pillar 4: 苦中有美（Hard to Live, Beautiful to Watch）
节目机位、慢仪式、日记和成片，让受苦值得回看。（对应美术圣经"冷与暖"。）

*Design test*: UI 数字和世界里的表现之间，选世界。

### Pillar 5: 亲手做（By Your Own Hands）
营地和里面的一切都是手搭的，是玩家自己的。

*Design test*: 自动建造和亲手摆放之间，选亲手。

### Anti-Pillars (What This Game Is NOT)

- **NOT 数值条杂务循环**：会让寒冷和美都变假（fire-before-dark PIVOT 的教训），违背"冷是真的"与"苦中有美"。
- **NOT 力量成长 / 技能树**：会破坏"越活越懂"。
- **NOT 轻松向、不能失败**：会破坏"冷是真的"。
- **NOT 战斗或有威胁的野兽（第一版）**：分散"人与寒冷、人与自己"的主题。
- **NOT 写实画风 / 永久房屋**：违背美术圣经与"亲手做"的临时感。

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| 《荒野独居》（*Alone*） | 规则与情绪：10 件装备、自拍日记、医疗检查、体重流失、退赛、名次 | 玩家同时是选手和镜头；局末剪成自己的一集 | 证明"一个人在荒野里慢慢垮掉"本身有张力 |
| *The Long Dark* | 知识型精通、寒冷作为主要敌人、无技能树 | 风格化扁平低模、高位远镜头、退赛赌注与心态 | 证明寒冷生存可以只靠知识成长 |
| *Firewatch* | 孤独的语气、美丽的风景承载情绪 | 生存压力是真的、会死 | 证明孤独和美可以同时成立 |
| B 站 Godot 雪地视频 | 构图与色块、高位镜头 | 加入身体与生存 | 视觉基准（见美术圣经） |

**Non-game inspirations**: 《荒野独居》节目本身；露营与荒野求生的真实体验（owner 的热爱）。

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 20–40 *(guessed)* |
| **Gaming experience** | Mid-core |
| **Time availability** | 工作日 45–90 分钟，周末更长 |
| **Platform preference** | PC（Mac 与 Windows） |
| **Current games they play** | *The Long Dark*；生存类与氛围类独立游戏 *(guessed)* |
| **What they're looking for** | 在游戏之余体验真正的野外独居：寒冷、饥饿、孤独与火边的安心 |
| **What would turn them away** | 杂务式数值管理、战斗、轻松向、写实但难看的画面 |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4.7（已配置，owner 选择）· GDScript · Forward+ · Jolt |
| **Key Technical Challenges** | 骨骼绑定与动画（幸存者模型未绑定）；深雪下陷与持久脚印；局末自动剪辑成片；多平台性能 |
| **Art Style** | 3D 风格化：扁平低模、逐面纯色、无贴图（见美术圣经） |
| **Art Pipeline Complexity** | Medium–High（Qwen 图 → Hunyuan3D LowPoly → Blender `flatten_glb.py` → GLB；动画需另建） |
| **Audio Needs** | Moderate→Adaptive（踩雪、风、火、呼吸；少量随心态变化的音乐状态） |
| **Networking** | None |
| **Content Volume** | 1 张地图起（之后解锁地点/季节）；约 30–50 种物品；一局数小时 *(provisional)* |
| **Procedural Systems** | 天气与资源分布有随机；地图手工制作 |

---

## Risks and Open Questions

### Design Risks
- 心态做成可见数值条会显得"游戏化"，失去节目里的情绪。
- 随机失败可能让人觉得不公平而不是无力。
- 纪念物"不给实质帮助"但又要"情绪安抚"——若心态影响动作可靠性，纪念物就间接有用；边界由 Kit Selection / Meta Rewards GDD 定清（Morale GDD 已在 Open Questions 挂出，待 owner 拍板）。
- 模拟对手看不见，可能撑不起退赛赌注。

### Technical Risks
- 骨骼绑定：程序化动作已被试玩否定；需要绑定 spike，失败则请 owner 协助（Mixamo / 手动 Blender）。
- 深雪下陷与持久脚印的性能，尤其将来移动端。
- 局末自动剪辑成片（选片段、取景、节奏）的规模未知。

### Market Risks
- 寒冷生存品类里已有成熟作品 (not researched)。
- 《荒野独居》观众与游戏玩家的重合程度 (not researched)。

### Scope Risks
- 33 个系统，solo 开发；8–10 个月估计长于 owner 说的"几个月"。
- 动画与成片剪辑都可能膨胀。

### Open Questions
- 一天的真实时长与夜间是否可跳过？— 用 MVP 试玩调。
- 奖励具体换来什么（纪念物、地点、季节）？— Meta Rewards GDD。
- 成片怎么剪：玩家挑还是自动？— Diary GDD 之前做纸面原型。

---

## MVP Definition

**Core hypothesis**: 在高位远镜头下，一个严酷的第一天和第一夜——沉重的身体陷在深雪里、可能失败的火、真的会咬人的冷、慢慢起毛边的心态——是紧张、看得清的，并且让玩家感到"只有我一个人"。

**Required for MVP**:
1. 绑定并有动画的角色在真实地形和深雪里行走、劳作（会陷入、留下痕迹）
2. 会失败、有可读原因的采集与多步生火
3. 真的会降的体温、需求与体重，以及心态与情绪表现（姿态、呼吸、调色、声音）
4. 昼夜与逐日变冷的压力曲线；极简 HUD

**Explicitly NOT in MVP** (defer to later):
- 庇护所、水、食物与动物、天气与寒潮、伤病（Vertical Slice）
- 装备选择、日记与成片、模拟对手、医疗检查、退赛结算（Vertical Slice）
- 存档、跨局奖励、本地化、无障碍（Alpha / Full Vision）

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 一片林间空地 + 湖岸 | 身体、雪地、生火、体温/需求/心态、情绪表现（18 个系统，见 systems-index） | 6–8 weeks |
| **Vertical Slice** | 一张完整地图 | 撑过三天、装备选择、日记、对手、医疗、退赛结算 | +8–10 weeks |
| **Alpha** | 地图 + 1 个解锁地点 | 全部系统粗糙可玩、存档、跨局纪念物 | +8 weeks |
| **Full Vision** | 多地点与季节、成片剪辑 | 打磨、中英文、Windows 实测、外部试玩 | +8 weeks |

如果时间不够：Vertical Slice 就是可发售的最小版本（一张地图、一季、退赛赌注），成片剪辑和解锁季节先砍。

---

## Next Steps

- [x] `/design-review design/gdd/game-concept.md`（2026-11-16 已评审）
- [x] 把 `design/gdd/systems-index.md` 的 Source Concept 指向本文件
- [ ] `/design-system morale-and-mental-state` — 设计顺序第 1，承载"感受 → 节目特征 → 机制"映射
- [ ] 继续 `/map-systems next` 完成 MVP 18 个 GDD
- [ ] 绑定 spike 与地形/深雪 spike（高风险，尽早）
- [ ] `/create-architecture` → ADR → `/gate-check`
