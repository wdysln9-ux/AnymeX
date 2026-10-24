import 'dart:math' as math;

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/database/isar_models/offline_media.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/screens/anime/details_page.dart';
import 'package:anymex/screens/library/controller/library_controller.dart';
import 'package:anymex/screens/library/editor/list_editor.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/screens/library/widgets/history_model.dart';
import 'package:anymex/screens/library/widgets/library_deps.dart';
// import 'package:anymex/screens/library/widgets/library_header.dart';
import 'package:anymex/screens/manga/details_page.dart';
import 'package:anymex/screens/novel/details/details_view.dart';
import 'package:anymex/screens/settings/widgets/history_card_gate.dart';
import 'package:anymex/screens/settings/widgets/history_card_selector.dart';
import 'package:anymex/utils/extension_utils.dart';
import 'package:anymex/utils/function.dart';

import 'package:anymex/widgets/common/cards/card_gate.dart';
import 'package:anymex/widgets/exceptions/empty_library.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:anymex/widgets/helper/tv_wrapper.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:anymex/widgets/common/scroll_aware_app_bar.dart';
import 'package:anymex/widgets/header/header.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter/services.dart';
import 'package:anymex/controllers/media_mode_controller.dart';

class MyLibrary extends StatefulWidget {
  final ItemType? type;
  const MyLibrary({super.key, this.type});

  @override
  State<MyLibrary> createState() => _MyLibraryState();
}

class _MyLibraryState extends State<MyLibrary>
    with AutomaticKeepAliveClientMixin {
  late final ScrollController _scrollController;
  final ValueNotifier<bool> _isAppBarVisibleExternally =
      ValueNotifier<bool>(true);
  late Worker _mediaModeWorker;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final mediaModeController = Get.put(MediaModeController());
    final libraryController = Get.put(LibraryController());

    libraryController.switchCategory(mediaModeController.mode);
    _mediaModeWorker = ever(mediaModeController.rxMode, (ItemType type) {
      libraryController.switchCategory(type);
    });
  }

  @override
  void didUpdateWidget(MyLibrary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.type != null && widget.type != oldWidget.type) {
      Get.find<LibraryController>().switchCategory(widget.type!);
    }
  }

  @override
  void dispose() {
    _mediaModeWorker.dispose();
    _scrollController.dispose();
    _isAppBarVisibleExternally.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = Get.find<LibraryController>();
    final isDesktop = MediaQuery.sizeOf(context).width > 600;
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    const appBarHeight = kToolbarHeight + 20;
    final settings = Get.find<Settings>();

    return Obx(() {
      final isLegacy = settings.useLegacyNavbar;
      final double extraHeight = isDesktop
          ? 100.0
          : (isLegacy ? 96.0 : 60.0);
      final double topOffset = statusBarHeight + appBarHeight + extraHeight;

      return Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: topOffset,
                  ),
                ),
                _LibraryContent(controller: controller),
              ],
            ),
            CustomAnimatedAppBar(
              isVisible: _isAppBarVisibleExternally,
              scrollController: _scrollController,
              headerContent: Obx(
                () => Header(
                  title: controller.showFolderOverview.value ? 'Daftar Tontonan' : 'Library',
                  subtitle: controller.showFolderOverview.value
                      ? '${controller.customLists.length} folder'
                      : 'All your local shi',
                  isSearchActive: controller.isSearchActive.value,
                  searchBar: HeaderSearchBar(
                    controller: controller.searchController,
                    onChanged: controller.search,
                    onClose: controller.toggleSearch,
                    hintText: 'Search in Library...',
                  ),
                  actions: [
                    HeaderActionButton(
                      icon: IconlyLight.search,
                      onTap: controller.toggleSearch,
                    ),
                    2.width(),
                    HeaderActionButton(
                      icon: Icons.sort_rounded,
                      onTap: () => showLibrarySortSheet(context, controller),
                    ),
                  ],
                  bottom: isLegacy
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LibrarySegmentedControl(controller: controller),
                            const SizedBox(height: 2),
                            ChipTabs(controller: controller),
                          ],
                        )
                      : ChipTabs(controller: controller),
                ),
              ),
              visibleStatusBarStyle: SystemUiOverlayStyle(
                statusBarIconBrightness:
                    Theme.of(context).brightness == Brightness.light
                        ? Brightness.dark
                        : Brightness.light,
                statusBarBrightness: Theme.of(context).brightness,
                statusBarColor: Colors.transparent,
              ),
              hiddenStatusBarStyle: SystemUiOverlayStyle(
                statusBarIconBrightness:
                    Theme.of(context).brightness == Brightness.light
                        ? Brightness.light
                        : Brightness.dark,
                statusBarBrightness:
                    Theme.of(context).brightness == Brightness.light
                        ? Brightness.dark
                        : Brightness.light,
                statusBarColor: Colors.transparent,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _LibraryContent extends StatelessWidget {
  final LibraryController controller;

  const _LibraryContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.rawItems.isEmpty) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      if (controller.showFolderOverview.value) {
        return _buildFolderOverview(context, controller);
      }

      final data = controller.processedItems;
      if (data.isEmpty) {
        return const SliverToBoxAdapter(child: EmptyLibrary());
      }

      if (controller.selectedListIndex.value == -1) {
        return _buildHistoryView(context, data);
      } else {
        return _buildGridView(context, data);
      }
    });
  }

  Widget _buildFolderOverview(BuildContext context, LibraryController controller) {
    final theme = Theme.of(context);
    final lists = controller.customLists;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 130),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151C27),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF263142)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FolderSummaryValue(
                          value: '${controller.rawItems.length}',
                          label: 'Total Disimpan',
                        ),
                      ),
                      Expanded(
                        child: _FolderSummaryValue(
                          value: '${lists.length}',
                          label: 'Folder',
                        ),
                      ),
                      const Expanded(
                        child: _FolderSummaryValue(
                          value: 'AnymeX',
                          label: 'Koleksi Kamu',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (index == 1) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Folder',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => navigate(
                        () => CustomListsEditor(type: controller.type.value),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Folder Baru'),
                    ),
                  ],
                ),
              );
            }

            final listIndex = index - 2;
            final list = lists[listIndex];
            final count = list.mediaIds?.length ?? 0;
            final isSelected = controller.selectedListIndex.value == listIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: const Color(0xFF1A232E),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => controller.selectList(listIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        SizedBox(
                           width: 68,
                           height: 68,
                           child: Stack(
                             alignment: Alignment.center,
                             children: [
                               Transform.rotate(
                                 angle: -0.13,
                                 child: Container(
                                   width: 37,
                                   height: 51,
                                   decoration: BoxDecoration(
                                     color: const Color(0xFF35435A),
                                     borderRadius: BorderRadius.circular(8),
                                     border: Border.all(color: const Color(0xFF526784)),
                                   ),
                                 ),
                               ),
                               Transform.rotate(
                                 angle: 0.13,
                                 child: Container(
                                   width: 37,
                                   height: 51,
                                   decoration: BoxDecoration(
                                     color: const Color(0xFF27374D),
                                     borderRadius: BorderRadius.circular(8),
                                     border: Border.all(color: const Color(0xFF405673)),
                                   ),
                                 ),
                               ),
                               Container(
                                 width: 39,
                                 height: 53,
                                 decoration: BoxDecoration(
                                   gradient: LinearGradient(
                                     begin: Alignment.topLeft,
                                     end: Alignment.bottomRight,
                                     colors: [
                                       theme.colorScheme.primary.withOpacity(0.95),
                                       const Color(0xFF334B70),
                                     ],
                                   ),
                                   borderRadius: BorderRadius.circular(9),
                                   boxShadow: [
                                     BoxShadow(
                                       color: theme.colorScheme.primary.withOpacity(0.18),
                                       blurRadius: 12,
                                       offset: const Offset(0, 5),
                                     ),
                                   ],
                                 ),
                                 child: const Icon(Icons.play_arrow_rounded,
                                     size: 25, color: Colors.white),
                               ),
                             ],
                           ),
                         ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                list.listName ?? 'Folder',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '$count anime',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.chevron_right_rounded : Icons.more_vert_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: lists.length + 2,
        ),
      ),
    );
  }

  Widget _buildHistoryView(BuildContext context, List<OfflineMedia> data) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 130),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: getResponsiveCrossAxisVal(
            MediaQuery.sizeOf(context).width - 120,
            itemWidth: 400,
          ),
          crossAxisSpacing: 10,
          mainAxisSpacing: 0,
          mainAxisExtent: getHistoryCardHeight(
            HistoryCardStyle.values[settingsController.historyCardStyle],
            context,
          ),
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final historyModel = HistoryModel.fromOfflineMedia(
              data[i],
              controller.type.value,
            );
            return HistoryCardGate(
              data: historyModel,
              cardStyle:
                  HistoryCardStyle.values[settingsController.historyCardStyle],
            );
          },
          childCount: data.length,
        ),
      ),
    );
  }

  Widget _buildGridView(BuildContext context, List<OfflineMedia> items) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
      sliver: SliverGrid(
        gridDelegate: _getSliverDelegate(context),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            OfflineMedia item = items[i];
            final tag =
                '${item.mediaId ?? item.id}-library-grid-${controller.type.value.name}';
            return AnymexOnTap(
              margin: 0,
              scale: 1,
              onTap: () => _handleItemTap(context, item, items, i, tag),
              child: MediaCardGate(
                itemData: items[i],
                tag: tag,
                variant: DataVariant.library,
                type: controller.type.value,
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  SliverGridDelegateWithFixedCrossAxisCount _getSliverDelegate(
      BuildContext context) {
    if (controller.gridCount.value == 0) {
      const horizontalPadding = 32.0;
      const crossAxisSpacing = 10.0;
      final availableWidth =
          MediaQuery.sizeOf(context).width - horizontalPadding;
      final isDesktop = getPlatform(context);
      final itemWidth = isDesktop ? 170.0 : 140.0;

      final crossAxisCount = math.max(
        1,
        ((availableWidth + crossAxisSpacing) / (itemWidth + crossAxisSpacing))
            .floor(),
      );

      return SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: 20,
        childAspectRatio: getGridCardAspectRatio(
          context: context,
          crossAxisCount: crossAxisCount,
          spacing: crossAxisSpacing,
          padding: horizontalPadding,
        ),
      );
    }

    final crossCount = math.max(1, controller.gridCount.value);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossCount,
      crossAxisSpacing: 0,
      mainAxisSpacing: 10,
      childAspectRatio: getGridCardAspectRatio(
        context: context,
        crossAxisCount: crossCount,
        spacing: 0,
        padding: 32.0,
      ),
    );
  }

  void _handleItemTap(BuildContext context, OfflineMedia item,
      List<OfflineMedia> items, int index, String tag) {
    if (controller.type.value.isAnime) {
      navigateWithAnimation(() => AnimeDetailsPage(
          media: Media.fromOfflineMedia(item, ItemType.anime), tag: tag));
    } else if (controller.type.value.isManga) {
      navigateWithAnimation(() => MangaDetailsPage(
          media: Media.fromOfflineMedia(item, ItemType.manga), tag: tag));
    } else {
      final sourceName = item.season ?? '';
      final source = sourceName.isNotEmpty
          ? sourceController.getNovelExtensionByName(sourceName)
          : null;

      navigateWithAnimation(() => NovelDetailsPage(
          source: source,
          media: Media.fromOfflineMedia(items[index], ItemType.novel),
          tag: tag));
    }
  }
}

class _FolderSummaryValue extends StatelessWidget {
  final String value;
  final String label;

  const _FolderSummaryValue({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF8995A5),
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}
