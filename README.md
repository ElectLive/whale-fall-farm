# 鲸落农场 · Whale Fall Farm

一个用 **Godot 4.7** 制作的小游戏：**农场经营 + Roguelike**。
白天在鲸背上种田，夜晚抵御从潮水里爬上来的怪物；每天黎明挑一份「潮汐祝福」、逛一次潮汐商店，撑过七个夜晚。

> 全部像素美术、背景音乐与音效都由仓库内的 Python 脚本程序化生成，没有任何外部素材包。

![标题界面](screenshots/shot_title.png)
![白天种田](screenshots/shot_day.png)
![雨天](screenshots/shot_rain.png)
![南瓜王](screenshots/shot_boss.png)
![黎明祝福](screenshots/shot_dawn.png)

## 玩法

- **白天（75 秒）**：走到田里，按 `E` 松土 → 播种 → 浇水 → 收获。作物只在浇过水之后生长。
- **天气**：每天有 30% 概率下雨。雨天会自动浇灌所有作物（包括新种下的），雨声和雨丝会一起出现。
- **夜晚**：潮水带来史莱姆、偷穗鸦、缠根怪和沼泽蛙。用镰刀清场；乌鸦会优先啃食成熟的作物。萤火虫会飘在田上。
- **黎明**：三选一随机祝福，然后可以在**潮汐商店**用金币买种子、回血、加生命上限。
- **第 7 夜**：腐化南瓜王苏醒。它会吐种子弹、在血量过半和残血时召唤潮泥怪；打倒它才能迎来胜利。
- **无尽模式**：通关后可以继续。每 3 天再战一次南瓜王，怪潮越来越厚，直到农场沉没。最佳纪录按存活天数结算。
- 地图装饰、天气、夜间波次、祝福与商店都是随机的，所以每一局都不一样。

## 作物

| 作物 | 种子价 | 生长 | 售价 | 特点 |
| --- | --- | --- | --- | --- |
| 萝卜 | 3 | 7s | 9 | 回本快 |
| 南瓜 | 9 | 13s | 24 | 稳健 |
| 星露花 | 20 | 20s | 54 | 最贵 |
| 月光麦 | 16 | 9s（仅夜晚） | 44 | 白天打盹，夜里疯长 |

## 操作

| 按键 | 作用 |
| --- | --- |
| `WASD` / 方向键 | 移动 |
| `E` | 互动：松土 / 播种 / 浇水 / 收获 |
| `1` `2` `3` `4` | 切换种子（萝卜 / 南瓜 / 星露花 / 月光麦） |
| `空格` / 鼠标左键 | 挥镰攻击（鼠标会朝指针方向挥） |
| `Esc` | 暂停（内有音乐 / 音效 / 全屏开关） |
| `M` | 快速开关音乐 |
| `F` | 全屏切换 |

## 运行

### 直接玩（推荐）

到 [Releases](https://github.com/ElectLive/whale-fall-farm/releases) 下载最新的 `WhaleFallFarm-v1.1.0-win64.zip`，解压后双击 `WhaleFallFarm.exe`。
存档与设置写在 exe 旁边，绿色免安装。

### 用 Godot 打开

需要 **Godot 4.7**（标准版，非 .NET）：

```bash
godot --path .
```

或者把本目录导入 Godot 项目管理器，按 F5。

## 从源码重新生成素材

```bash
python tools/gen_art.py     # 76 张像素图 + 图标（需要 Pillow）
python tools/gen_audio.py   # 4 首循环 BGM + 17 个音效 + 1 条雨声（需要 numpy）
```

脚本是确定性的：同一个脚本每次生成同样的素材，方便 diff 和复现。

## 开发自检

```bash
# 无头逻辑测试：种田、昼夜、商店、祝福、Boss、无尽、天气、月光麦、音乐开关、存档
Godot --headless --path . -- --selftest     # 47/47 PASS

# 实时冒烟测试：真的种一轮、传送到怪身边砍死几只、进入黎明
Godot --headless --path . -- --smoke

# 截图（输出到 screenshots/）
Godot --path . -- --shot=title   # title / day / night / boss / dawn / shop / pause / victory / gameover
```

导出 Windows 版：

```bash
Godot --headless --path . --export-release "Windows Desktop" build/windows/WhaleFallFarm.exe
```

## 项目结构

```
assets/
  font/                 Cubic 11 像素字体（OFL）
  generated/            由脚本生成的图、音、图标
scripts/
  main.gd               游戏状态机、昼夜循环、战斗、商店、经济、存档钩子
  farm.gd / crop.gd     农田网格与作物生长
  player.gd / enemy.gd  玩家与怪物（含南瓜王）
  projectile.gd         南瓜王吐出的种子
  sea.gd / island.gd    鲸背小岛与海面
  hud.gd                HUD、Boss 血条、横幅提示、低血量红框
  title_screen.gd       标题界面
  dawn_screen.gd        黎明祝福三选一 + 潮汐商店
  end_screen.gd         结算界面
  pause_screen.gd       暂停 + 音频/全屏设置
  audio.gd              音乐/音效、音量开关
  save_game.gd          本地记录与设置
  dev.gd                selftest / smoke / 截图钩子
tools/
  gen_art.py            程序化像素美术
  gen_audio.py          程序化 chiptune 音乐与音效
docs/
  design.md             设计文档与数值表
  devlog.md             版本日志与验证记录
  art_preview.png       素材总览
```

## 设计备注

- 分辨率 1280×720，相机固定 4 倍缩放，保证像素对齐；UI 使用 12px 像素字体 Cubic 11。
- 美术全部以 16×16 为基础手写绘制代码；角色 16×24，4 方向 4 帧；Boss 32×32。
- 音乐是 numpy 合成的方波/三角波/噪声，按和弦进行生成，WAV 循环播放；第 7 夜有独立 Boss 曲。
- 数值（作物价格、怪物血量、波次、商店价格）集中在 `scripts/data.gd`，方便调整。
- 每局随机：地图种子、波次顺序、出生点、祝福三选一、商店三件商品、掉落。

## 版本

- **v0.1.0** — 完整核心循环：种田、昼夜、三种怪物、12 种祝福、7 天胜利、结算与本地最佳记录。
- **v0.2.0** — 黎明潮汐商店；第 7 夜 Boss「腐化南瓜王」（种子弹幕、召唤小怪、Boss 血条）；横幅、粒子、新音效；selftest 扩到 32 项。
- **v0.3.0** — 音乐/音效/全屏设置与暂停菜单；2 个新祝福（潮雾提灯、绿拇指）；Boss 专属 BGM 与胜负音效；夜晚萤火虫、低血量红框、作物阶段弹跳；截图与文档更新。
- **v1.0.0** — 无尽模式（通关后继续，每 3 天再战南瓜王）；记录/最佳成绩在无尽中继续更新；最终平衡与发布构建；selftest 扩到 40 项。
- **v1.1.0** — 第 4 种作物「月光麦」（只在夜里生长）；新怪物「沼泽蛙」；雨天天气（自动浇水 + 雨丝 + 雨声）；4 格种子栏；selftest 扩到 47 项。

## License

- 代码：MIT，见 [LICENSE](LICENSE)。
- 程序生成的图像与音频：CC0-1.0（可随意使用）。
- 字体：[Cubic 11](https://github.com/ACh-K/Cubic-11)，SIL Open Font License 1.1，见 [assets/font/OFL.txt](assets/font/OFL.txt)。

---

用 [DeepSeek Harness](https://github.com/deepseek-ai/dsh) 制作。美术与音乐没有借助任何外部素材。
