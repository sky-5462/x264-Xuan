# x264-Xuan

想不到这个玩玩的项目居然是我HPC的入门

主要是为了自己爽，进行了巨量的魔改，相当于在configure阶段硬编码了以下配置：

1. --bit-depth=8. 8bit420是最广泛使用的类型，其它类型基本的硬解都没有，不如交给HEVC
2. --chroma-format=420. 同上
3. --disable-opencl. opencl在这里好像是负优化，不如SIMD，真的有足够的数据规模抵消开销吗？
4. --disable-avs. 基本上前端接vapoursynth，后端接封装器，编码器这里只保留最小的格式支持就行
5. --disable-swscale. 同上
6. --disable-lavf. 同上
7. --disable-ffms. 同上
8. --disable-gpac. 反正还要封装音频流，直接输出裸视频流就好
9. --disable-lsmash. 同上
10. --disable-interlaced. 隔行是天坑，坏文明，看不爽直接毙掉
11. --enable-lto. 优化性能

对CPU的要求，保证自己手搓汇编的体验：

1. 只支持x86_64，不支持32bit，不支持其它ISA
2. 最低要求Haswell这代，也就是支持AVX2/FMA/BMI2

然后是相当于在命令行参数里硬编码了以下选项：

1. --partitions all. 质量优先
2. --direct auto. 质量优先
3. --weightp 2. 从来没动过，似乎能提升质量
4. --me umh. umh刚好性能和质量均衡，再往上的esa性能需求极大提高，但收益痕量甚至负优化，反正我用不到
5. --trellis 2. 其它的选项没用过，质量优先
6. --no-fast-pskip. 质量优先
7. --slow-firstpass. 默认的pass1会使用一些这里去掉的选项，解除限制
8. --nr 0. 降噪交给前端
9. --cqm flat. jvt目前没见到有人用过

以下选项有一些限制：

1. --aq-mode > 0. 自适应量化必开，不过可以选模式调节下
2. --subme > 8. 低等级的没必要，质量优先，留下9/10/11三个可以微调看看

以下这些选项无效：

1. --open-gop. 开了可能拖进度条花屏是个坑，用min-keyint配合close-gop没任何问题
2. --no-cabac. 算力足够，提高压缩率
3. --tff/--bff/--fake-interlaced. 隔行的选项，爬
4. --pulldown. 帧率的事情丢给前端
5. --no-weightb. 从来没关过，似乎能提升质量
6. --no-psy. 跑分选项，这里没用
7. --no-mixed-refs. 降画质提速度，丢掉
8. --no-chroma-me. 同上
9. --no-8x8dct. 同上
10. --no-dct-decimate. 同上
11. --cqm相关的自定义选项
12. --bluray-compat. 蓝光碟兼容大可不必，我又不可能发碟
