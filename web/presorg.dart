import 'dart:html';

abstract class AbstractSlide {
  Element element;
  Element tocListItem;
  final List<String> classNames = ['far-past', 'past', 'next', 'far-next', 'current'];
  Set<Function> inFunctions = new Set();
  Set<Function> outFunctions = new Set();
  
  AbstractSlide(Element ele) {
    this.element = ele;
    tocListItem = document.query('a[href="${this.getSecID()}"]').parent;
  }
  
  abstract void makeFarPast();
  abstract void makePast();
  abstract void makeCurrent();
  abstract void makeNext();
  abstract void makeFarNext();
  
  String getSecID() {
    String toRemove = 'outline-container-';
    return "#sec-${element.id.substring(toRemove.length, element.id.length)}";
  }
  
  void resetPositionClassTo(String newClassName) {
    if (newClassName == 'current') {
      inFunctions.forEach((func) => func(this.element));
    } else if (!element.classes.contains(newClassName)){
      outFunctions.forEach((func) => func(this.element));
    }
    for (var className in classNames) {
      if (className == newClassName) {
        element.classes.add(className);
      } else {
        element.classes.remove(className);
      }
    }
  }

}

class SectionSlide extends AbstractSlide {
  
  SectionSlide(Element element) : super(element);
  
  void hideSubsections() {
    element.queryAll('.outline-3').forEach((subSection) {
      subSection.classes.add('hidden');
    });
  }
  
  void makeFarPast() {
    resetPositionClassTo('far-past');
    hide();
  }
  
  void makePast() {
    resetPositionClassTo('past');
    hide();
  }
  
  void makeCurrent() {
    hideSubsections();
    updateTOC();
    resetPositionClassTo('current');
    show();
  }
  
  void makeNext() {
    resetPositionClassTo('next');
    hide();
  }
  
  void makeFarNext() {
    resetPositionClassTo('far-next');
    hide();
  }
  
  void hide() {
    element.queryAll(':root > div:not(.outline-3)').forEach((element) {
      element.classes.add('hidden');
    });
  }
  
  void show() {
    element.queryAll(':root > div:not(.outline-3)').forEach((element) {
      element.classes.remove('hidden');
    });
  }
  
  void updateTOC() {
    // Remove the toc-highlight from current sections
    document.queryAll('#text-table-of-contents > ul > li.toc-highlight').forEach((element) {
      element.classes.remove("toc-highlight");
    });
    
    // Remove the toc-highlight from current subsections
    document.queryAll('#text-table-of-contents > ul > li > ul > li.toc-highlight').forEach((element) {
      element.classes.remove("toc-highlight");
    });
    
    // Add the toc-highlight to the current section entry
    tocListItem.classes.add("toc-highlight");
  }
  
}

class SubSectionSlide extends AbstractSlide {
  
  SubSectionSlide(Element element) : super(element);
  
  void makeFarPast() {
    resetPositionClassTo('far-past');
  }
  
  void makePast() {
    resetPositionClassTo('past');
  }
  
  void makeCurrent() {
    element.classes.remove('hidden');
    updateTOC();
    resetPositionClassTo('current');
  }
  
  void makeNext() {
    resetPositionClassTo('next');
  }
  
  void makeFarNext() {
    resetPositionClassTo('far-next');
  }
  
  void updateTOC() {
    
    // Remove the highlight from any section that is not this subsection's parent
    // This is necessary when moving backwards though from one section to the preceeding subsection.
    document.queryAll('#text-table-of-contents > ul > li.toc-highlight').forEach((element) {
      if (element != tocListItem.parent.parent) {
        element.classes.remove('toc-highlight');
        tocListItem.parent.parent.classes.add('toc-highlight');
      }
    });
    
    // Remove the toc-highlight from all other subsections
    document.queryAll('#text-table-of-contents > ul > li > ul > li.toc-highlight').forEach((element) {
      element.classes.remove("toc-highlight");
    });
    
    
    // Add the highlight to our subsection
    tocListItem.classes.add("toc-highlight");
    
  }

}

class SlideController {
  List<AbstractSlide> slides = [];
  List<Element> toc = [];
  num cursor = -1;
  Map<String, Function> bonusClasses = new Map();
  DivElement slideCounter = new DivElement();
  
  SlideController() {
    addSlides();
    addEventListeners();
    slideCounter.id = 'slide-counter';
  }
  
  void shortenTOC() {
    document.queryAll('#text-table-of-contents > ul > li > ul > li > a').forEach((element) {
      element.innerHTML = '●';
    });
    
    document.query('#text-table-of-contents').insertAdjacentElement('AfterEnd', slideCounter);
  }
  
	void addEventListeners() {
    document.on.keyDown.add((KeyboardEvent event) {
      switch(event.keyCode) {
        case 39: // Right arrow
        case 13: // Enter
        case 32: // Space bar
        case 34: // Page down
          nextSlide();
          event.preventDefault();
          break;
        case 37: // Left arrow
        case 8:  // Backspace
        case 33: // Page up
          prevSlide();
          event.preventDefault();
          break;
        case 72: // 'h' key
          toggleCodeHighlight();
          break;
        case 36: // Home key
          cursor = -1;
          nextSlide();
          break;
        case 35: // End key
          cursor = slides.length - 2;
          nextSlide();
          break;
        default:
          break;
      }
    });
    
    window.on.hashChange.add((HashChangeEvent event) {
      updateCursorFromHash();
      updateSlideClasses();
    });
  }
	
	void toggleCodeHighlight() {
	  List<Element> offCode = slides[cursor].element.queryAll('.coderef-off');
	  List<Element> onCode = slides[cursor].element.queryAll('.code-highlighted');
	  
	  offCode.forEach((element) {
	    element.classes.remove('coderef-off');
	    element.classes.add('code-highlighted');
	  });
	  
	  onCode.forEach((element) {
      element.classes.remove('code-highlighted');
      element.classes.add('coderef-off');
	  });
	}
	
	void addSlides() {
    document.queryAll('.outline-2,.outline-3').forEach((element) {
      AbstractSlide slide;
      if (element.classes.contains('outline-2')) {
        slide = new SectionSlide(element);
      } else if (element.classes.contains('outline-3')) {
        slide = new SubSectionSlide(element);
      } else {
        throw new IndexOutOfRangeException('Cannot find the required class (outline-2 or outline-3) in element: $element');
      }
      slides.add(slide);
    });
  }
	
	void updateHash() {
	  AbstractSlide currentSlide = slides[cursor];
	  if (currentSlide != null) {
	    String hashID = currentSlide.getSecID();
	    slideCounter.innerHTML = '${cursor + 1} / ${slides.length}';
	    window.location.hash = currentSlide.getSecID();
	  }
	}
	
	void updateCursorFromHash() {
    for (var i = 0; i < slides.length; i++) {
      if (slides[i].getSecID() == window.location.hash) {
        cursor = i;
      }
    }
	}
	
	void nextSlide() {
    if ((cursor + 1) < slides.length) {
	    cursor++;
	    updateHash();
	  }
	}
	
	void prevSlide() {
    if (cursor > 0) {
	    cursor--;
      updateHash();
	  }
	}
	
	void updateSlideClasses() {
    for (var i = 0; i < slides.length; i++) {
      switch (i - cursor) {
        case -1:
          slides[i].makePast();
          break;
        case 0:
          slides[i].makeCurrent();
          break;
        case 1:
          slides[i].makeNext();
          break;
        default:
          if (i - cursor > 0) {
            slides[i].makeFarNext();
          } else {
            slides[i].makeFarPast();
          }
          break;
      }
    }
	}
  
	void addInFunction(String className, Function inFunction) {
	  slides.filter((slide) => slide.element.classes.contains(className)).forEach((slide) {
	    slide.inFunctions.add(inFunction);
	  });
	}
	
	void addOutFunction(String className, Function outFunction) {
    slides.filter((slide) => slide.element.classes.contains(className)).forEach((slide) {
      slide.outFunctions.add(outFunction);
    });
	}
	
	void startSlideShow() {
    shortenTOC();
    updateCursorFromHash();
    updateSlideClasses();
	}
	
}


void alertIn(Element inboundSlide) => document.body.classes.add('alert');
bool alertOut(Element outboundSlide) => document.body.classes.remove('alert');

void sootheIn(Element inboundSlide) => document.body.classes.add('soothe');
bool sootheOut(Element outboundSlide) => document.body.classes.remove('soothe');

void sectionIn(Element inboundSlide) => document.body.classes.add('section-title');
bool sectionOut(Element outboundSlide) => document.body.classes.remove('section-title');

void main() {
  var controller = new SlideController();
  controller.addInFunction('alert', alertIn);
  controller.addOutFunction('alert', alertOut);
  
  controller.addInFunction('soothe', sootheIn);
  controller.addOutFunction('soothe', sootheOut);
  
  controller.addInFunction('outline-2', sectionIn);
  controller.addOutFunction('outline-2', sectionOut);
  
  controller.startSlideShow();
}