import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../models/score_type.dart';

/// 악보 뷰어 위젯
/// PDF와 이미지를 표시하고, 페이지 제어 기능을 제공합니다.
class ScoreViewer extends StatefulWidget {
  final List<String> filePaths;
  final ScoreType type;
  final int currentPage; // 부모로부터 주입받는 현재 페이지
  final Function(int) onPageChanged; // 페이지 변경 시 부모에게 알리는 콜백 (사용자 수동 스크롤 감지)
  
  const ScoreViewer({
    super.key,
    required this.filePaths,
    required this.type,
    required this.currentPage,
    required this.onPageChanged,
  });

  // 하위 호환성을 위한 생성자 (기본값 사용)
  factory ScoreViewer.fromSinglePath(String filePath, {Key? key, int currentPage = 0, Function(int)? onPageChanged}) {
    return ScoreViewer(
      key: key,
      filePaths: [filePath],
      type: filePath.toLowerCase().endsWith('.pdf') ? ScoreType.pdf : ScoreType.image,
      currentPage: currentPage,
      onPageChanged: onPageChanged ?? (int page) {},
    );
  }

  @override
  State<ScoreViewer> createState() => ScoreViewerState();
}

class ScoreViewerState extends State<ScoreViewer> {
  // PDF용 컨트롤러
  PDFViewController? _pdfController;
  
  // 이미지용 PageController (다중 이미지 및 단일 이미지 모두 사용)
  PageController? _pageController;
  
  // PDF 총 페이지 수
  int _totalPages = 0;
  
  // 현재 페이지를 내부적으로 추적 (동기화용)
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.currentPage;
    
    // 이미지 타입인 경우 PageController 생성
    if (widget.type == ScoreType.image) {
      _pageController = PageController(
        initialPage: widget.currentPage.clamp(0, widget.filePaths.length - 1),
      );
    }
    
    // 초기 총 페이지 수 설정
    if (widget.type == ScoreType.pdf) {
      // PDF는 onRender에서 실제 페이지 수를 받아옴
      _totalPages = 0;
    } else {
      // 이미지는 파일 개수가 페이지 수
      _totalPages = widget.filePaths.length;
    }
  }

  @override
  void didUpdateWidget(ScoreViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // currentPage가 외부에서 변경되었을 때 동기화
    if (widget.currentPage != oldWidget.currentPage) {
      _currentPageIndex = widget.currentPage;
      
      if (widget.type == ScoreType.pdf) {
        // PDF의 경우 PDFViewController를 통해 페이지 설정
        if (_pdfController != null && 
            widget.currentPage >= 0 && 
            widget.currentPage < _totalPages) {
          _pdfController!.setPage(widget.currentPage);
        }
      } else {
        // 이미지의 경우 PageController를 통해 페이지 설정
        if (_pageController != null && 
            widget.currentPage >= 0 && 
            widget.currentPage < widget.filePaths.length &&
            (_pageController!.page?.round() != widget.currentPage)) {
          _pageController!.jumpToPage(widget.currentPage);
        }
      }
    }
    
    // filePaths나 type이 변경된 경우 PageController 재생성
    if (widget.type != oldWidget.type || widget.filePaths != oldWidget.filePaths) {
      if (widget.type == ScoreType.image) {
        _pageController?.dispose();
        _pageController = PageController(
          initialPage: widget.currentPage.clamp(0, widget.filePaths.length - 1),
        );
        _totalPages = widget.filePaths.length;
      }
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  /// 특정 페이지로 이동
  /// PDF: pdfController.setPage(page) 호출
  /// 이미지: pageController.jumpToPage(page) 호출
  void goToPageIndex(int pageIndex) {
    if (pageIndex < 0) {
      debugPrint('ScoreViewer: goToPageIndex - ERROR: pageIndex ($pageIndex) is negative');
      return;
    }
    
    debugPrint('ScoreViewer: goToPageIndex - pageIndex: $pageIndex, type: ${widget.type}');
    
    if (widget.type == ScoreType.pdf) {
      // PDF의 경우
      debugPrint('ScoreViewer: goToPageIndex - PDF, totalPages: $_totalPages, controller: ${_pdfController != null}');
      
      if (_pdfController == null) {
        debugPrint('ScoreViewer: goToPageIndex - ERROR: PDF controller is null!');
        // PDF 컨트롤러가 아직 초기화되지 않았으면, 나중에 다시 시도할 수 있도록
        // 하지만 현재는 그냥 스킵 (PDF는 onViewCreated에서 컨트롤러가 설정됨)
        return;
      }
      
      // PDF가 아직 렌더링되지 않았을 수 있지만, 일단 시도
      // PDFView는 내부적으로 페이지를 처리할 수 있음
      if (_totalPages > 0 && pageIndex >= _totalPages) {
        debugPrint('ScoreViewer: goToPageIndex - ERROR: pageIndex ($pageIndex) >= totalPages ($_totalPages)');
        return;
      }
      
      if (_totalPages == 0) {
        debugPrint('ScoreViewer: goToPageIndex - WARNING: PDF totalPages is 0, page may not be rendered yet, but attempting anyway');
      }
      
      debugPrint('ScoreViewer: goToPageIndex - calling PDF setPage($pageIndex)');
      try {
        // 🔥 CRITICAL: PDF 페이지 설정을 강제로 실행
        // 갤럭시 탭 S10+에서도 작동하도록 명시적으로 호출
        _pdfController!.setPage(pageIndex);
        _currentPageIndex = pageIndex;
        
        // 페이지 변경이 즉시 반영되도록 강제
        // onPageChanged 콜백을 수동으로 호출하여 동기화
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onPageChanged(pageIndex);
            debugPrint('ScoreViewer: goToPageIndex - PDF onPageChanged callback manually triggered for page $pageIndex');
          }
        });
        
        debugPrint('ScoreViewer: goToPageIndex - PDF setPage($pageIndex) completed successfully');
        // onPageChanged는 PDFView의 onPageChanged 콜백에서도 자동으로 호출됨
      } catch (e, stackTrace) {
        debugPrint('ScoreViewer: goToPageIndex - ERROR: PDF setPage failed: $e');
        debugPrint('ScoreViewer: goToPageIndex - Stack trace: $stackTrace');
        
        // 에러 발생 시 재시도 로직 (특정 기기에서 필요할 수 있음)
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _pdfController != null) {
            try {
              debugPrint('ScoreViewer: goToPageIndex - Retrying PDF setPage($pageIndex)');
              _pdfController!.setPage(pageIndex);
              _currentPageIndex = pageIndex;
            } catch (retryError) {
              debugPrint('ScoreViewer: goToPageIndex - Retry also failed: $retryError');
            }
          }
        });
      }
    } else {
      // 이미지의 경우 PageController 사용
      debugPrint('ScoreViewer: goToPageIndex - Image, filePaths.length: ${widget.filePaths.length}');
      
      if (_pageController == null) {
        debugPrint('ScoreViewer: goToPageIndex - ERROR: PageController is null!');
        // PageController가 null이면 재생성
        _pageController = PageController(
          initialPage: pageIndex.clamp(0, widget.filePaths.length - 1),
        );
        debugPrint('ScoreViewer: goToPageIndex - PageController recreated with initialPage: ${pageIndex.clamp(0, widget.filePaths.length - 1)}');
      }
      
      if (pageIndex >= widget.filePaths.length) {
        debugPrint('ScoreViewer: goToPageIndex - ERROR: pageIndex ($pageIndex) >= filePaths.length (${widget.filePaths.length})');
        return;
      }
      
      debugPrint('ScoreViewer: goToPageIndex - calling Image jumpToPage($pageIndex)');
      try {
        // 🔥 CRITICAL: 이미지 페이지 설정을 강제로 실행
        _pageController!.jumpToPage(pageIndex);
        _currentPageIndex = pageIndex;
        
        // 페이지 변경이 즉시 반영되도록 강제
        // onPageChanged 콜백을 수동으로 호출하여 동기화
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onPageChanged(pageIndex);
            debugPrint('ScoreViewer: goToPageIndex - Image onPageChanged callback manually triggered for page $pageIndex');
          }
        });
        
        debugPrint('ScoreViewer: goToPageIndex - Image jumpToPage($pageIndex) completed successfully');
        // onPageChanged는 PageView의 onPageChanged 콜백에서도 자동으로 호출됨
      } catch (e, stackTrace) {
        debugPrint('ScoreViewer: goToPageIndex - ERROR: Image jumpToPage failed: $e');
        debugPrint('ScoreViewer: goToPageIndex - Stack trace: $stackTrace');
        
        // 에러 발생 시 재시도 로직
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _pageController != null) {
            try {
              debugPrint('ScoreViewer: goToPageIndex - Retrying Image jumpToPage($pageIndex)');
              _pageController!.jumpToPage(pageIndex);
              _currentPageIndex = pageIndex;
            } catch (retryError) {
              debugPrint('ScoreViewer: goToPageIndex - Retry also failed: $retryError');
            }
          }
        });
      }
    }
  }
  
  /// 다음 페이지로 이동
  /// PDF: pdfController.setPage(currentPage + 1) 호출
  /// 이미지: pageController.nextPage() 호출
  void nextPageIndex() {
    final currentPage = _currentPageIndex;
    final nextPage = currentPage + 1;
    
    debugPrint('ScoreViewer: nextPageIndex - currentPage: $currentPage, nextPage: $nextPage');
    
    if (widget.type == ScoreType.pdf) {
      // PDF의 경우
      debugPrint('ScoreViewer: nextPageIndex - PDF, totalPages: $_totalPages');
      if (_totalPages > 0 && nextPage < _totalPages && _pdfController != null) {
        debugPrint('ScoreViewer: nextPageIndex - calling setPage($nextPage)');
        _pdfController!.setPage(nextPage);
        // onPageChanged는 PDFView의 onPageChanged 콜백에서 자동으로 호출됨
      } else {
        debugPrint('ScoreViewer: nextPageIndex - PDF page flip skipped (totalPages: $_totalPages, nextPage: $nextPage, controller: ${_pdfController != null})');
      }
    } else {
      // 이미지의 경우
      debugPrint('ScoreViewer: nextPageIndex - Image, filePaths.length: ${widget.filePaths.length}');
      if (_pageController != null && nextPage < widget.filePaths.length) {
        debugPrint('ScoreViewer: nextPageIndex - calling nextPage()');
        _pageController!.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        // onPageChanged는 PageView의 onPageChanged 콜백에서 자동으로 호출됨
      } else {
        debugPrint('ScoreViewer: nextPageIndex - Image page flip skipped (filePaths.length: ${widget.filePaths.length}, nextPage: $nextPage, controller: ${_pageController != null})');
      }
    }
  }

  /// PDF 뷰어 빌드
  /// flutter_pdfview 패키지의 PDFView 위젯을 사용
  Widget _buildPdfViewer() {
    if (widget.filePaths.isEmpty) {
      return const Center(
        child: Text('PDF 파일을 찾을 수 없습니다'),
      );
    }
    
    return PDFView(
      filePath: widget.filePaths[0], // PDF는 첫 번째 파일만 사용
      enableSwipe: true,
      swipeHorizontal: true,
      autoSpacing: false,
      pageFling: true,
      defaultPage: widget.currentPage.clamp(0, 999), // 초기 페이지 설정
      onRender: (pages) {
        // PDF 렌더링 완료 시 총 페이지 수 업데이트
        debugPrint('ScoreViewer: PDF onRender - pages: $pages');
        if (mounted) {
          setState(() {
            _totalPages = pages ?? 0;
          });
          debugPrint('ScoreViewer: PDF onRender - _totalPages updated to $_totalPages');
          
          // 현재 페이지가 설정되어 있으면 즉시 이동
          if (_pdfController != null && widget.currentPage > 0 && _totalPages > 0) {
            final targetPage = widget.currentPage.clamp(0, _totalPages - 1);
            if (targetPage != _currentPageIndex) {
              debugPrint('ScoreViewer: PDF onRender - setting page to $targetPage after render');
              _pdfController!.setPage(targetPage);
              _currentPageIndex = targetPage;
            }
          }
        }
      },
      onViewCreated: (PDFViewController controller) {
        // PDFViewController 저장
        debugPrint('ScoreViewer: PDF onViewCreated - controller initialized');
        _pdfController = controller;
        
        // 초기 페이지 설정 (onViewCreated가 호출될 때)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            debugPrint('ScoreViewer: PDF onViewCreated postFrameCallback - currentPage: ${widget.currentPage}, totalPages: $_totalPages');
            if (widget.currentPage > 0 && _totalPages > 0) {
              final targetPage = widget.currentPage.clamp(0, _totalPages - 1);
              debugPrint('ScoreViewer: PDF onViewCreated - setting initial page to $targetPage');
              controller.setPage(targetPage);
            } else if (widget.currentPage == 0) {
              // 첫 페이지는 명시적으로 설정하지 않아도 되지만, 안전을 위해 설정
              debugPrint('ScoreViewer: PDF onViewCreated - currentPage is 0, no need to set');
            }
          }
        });
      },
      onPageChanged: (int? page, int? total) {
        // 사용자가 수동으로 페이지를 변경한 경우 부모에게 알림
        if (page != null && mounted) {
          _currentPageIndex = page;
          widget.onPageChanged(page);
        }
      },
    );
  }

  /// 이미지 뷰어 빌드
  /// 다중 이미지: PageView.builder 사용
  /// 단일 이미지: PageView.builder 사용 (일관성을 위해)
  Widget _buildImageViewer() {
    if (widget.filePaths.isEmpty) {
      return const Center(
        child: Text('이미지 파일을 찾을 수 없습니다'),
      );
    }
    
    // 다중 이미지 및 단일 이미지 모두 PageView.builder 사용
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.filePaths.length,
      scrollDirection: Axis.horizontal,
      physics: const PageScrollPhysics(), // 스와이프 가능하도록
      onPageChanged: (index) {
        // 사용자가 수동으로 페이지를 변경한 경우 부모에게 알림
        if (mounted) {
          _currentPageIndex = index;
          widget.onPageChanged(index);
        }
      },
      itemBuilder: (context, index) {
        return Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.file(
              File(widget.filePaths[index]),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text('이미지를 불러올 수 없습니다'),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == ScoreType.pdf) {
      return _buildPdfViewer();
    } else {
      return _buildImageViewer();
    }
  }

  // 하위 호환성을 위한 메서드들
  void goToPage(int page) {
    goToPageIndex(page);
  }

  void nextPage() {
    nextPageIndex();
  }
}