from calibre_plugins.osis_input.osis import OsisHandler
from calibre_plugins.osis_input.structure import OsisError
import shutil
import re
import unicodedata

class GlossaryHandler(OsisHandler):
    def __init__(self, htmlWriter, context):
        OsisHandler.__init__(self, htmlWriter, context)
        self._endDfn = False                            # Just written </dfn> tag
        self._glossTitleWritten = False                 # The title for the glossary has been written out
        self._inArticle = False                         # Currently processing a glossary entry
        self._inChapterTitle = False                    # The title currently being processed is a chapter title
        self._inDfn = False                             # Currently within an OSIS <seg> tag for a keyword
        
    def startDocument(self):
        OsisHandler.startDocument(self)
        self._endDfn = False
        self._glossTitleWritten = False
        self._headerProcessed = False
        self._inArticle = False
        self._inChapterTitle = False
        self._inDfn = False
        self._defaultHeaderLevel = 3                    # Avoid header level 2 as this would appear in table of contents

        # If there are multiple glossaries and Testament headers are used,
        # create an overall title for the glossaries at the Testament level if title is set in config
        if len(self._context.glossaries) > 1 and self._context.topHeaderLevel == 1 and self._context.config.glossTitleSet:
            self._htmlWriter.open('glossary.txt')
            self._htmlWriter.write('<h1>%s</h1>\n' % self._context.config.glossaryTitle)
            self._htmlWriter.close()
            self._context.topHeaderLevel = 2
       
    def endDocument(self):
        self._footnotes.writeFootnotes()
        OsisHandler.endDocument(self)
        
    def startElement(self, name, attrs):
        if not self._inWork:
            OsisHandler.startElement(self, name, attrs)
                        
    def endElement(self, name):
        if name == 'chapter':
            self._endArticle()
            
        elif name == 'div':
            self._endArticle()
            
        elif name == 'p':
            self._endDfn = False
            OsisHandler.endElement(self, name)
            
        elif name == 'seg':
            if self._inDfn:
                self._writeHtml('</dfn>')
                self._inDfn = False
                self._endDfn = True
                
        elif name == 'title':
            if self._inTitle:
                self._inTitle = False
                if self._ignoreTitle:
                    self._ignoreTitle = False                       
                elif self._headerProcessed:
                    if self._inChapterTitle:
                        if self._context.topHeaderLevel == 1:
                            self._titleTag = '<h2>'
                        else:
                            self._titleTag = '<h3 chapter="%s">' % self._titleText 
                        self._inChapterTitle = False
                    else:
                        self._glossTitleWritten = True
                    self._writeTitle()
                    
        else:
            OsisHandler.endElement(self, name)
 
    def characters(self, content):
        text = content.strip()
        
        if self._inTitle:
            if self._headerProcessed:
                if not self._ignoreTitle:
                    self._writeHtml(content)
                    
        else :
            if self._headerProcessed:           
                if not self._ignoreText:
                    if len(text) > 0:
                        if not self._glossTitleWritten and not self._inTitle:
                            self._writeDefaultTitle()                                        
                        if not self._inParagraph and not self._inGeneratedPara and not self._inArticle and not self._lineGroupPara and not self._inTable:
                            self._startGeneratedPara()
                        if self._endDfn:
                            if unicodedata.category(content[0]) == 'Pd':
                                self._writeHtml(' ')
                            elif content[0] == ' ':
                                if unicodedata.category(text[0]) != 'Pd':
                                    self._writeHtml(u' \u2014')
                            else:
                                self._writeHtml(u' \u2014 ')
                            self._endDfn = False
                        self._writeHtml(content)
                        
    # The _processBodyTag function is called from the base class startElement
    def _processBodyTag(self, name, attrs):
        if name == 'chapter':
            self._endArticle()
                                  
        elif name == 'div':
            divType = self._getAttributeValue(attrs, 'type')
            if divType == 'glossary':
                print 'Opening html file'
                self._htmlWriter.open(self._osisIDWork)
                self._breakCount = 2
            else:
                typeStr = ''
                if divType is not None:
                    typeStr = 'type %s' % divType
                print 'Unexpected <div> found - type %s' % typeStr
                
        elif name == 'reference':
            # reference are ignored apart from glossary references
            refType = self._getAttributeValue(attrs, 'type')
            if refType == "x-glosslink" and self._endDfn:
                self._writeHtml(u' \u2014 ')
                self._endDfn = False
            OsisHandler._processReference(self, attrs)

        elif name == 'seg':
            segType = self._getAttributeValue(attrs, 'type')
            if segType == 'keyword':
                self._closeParagraph()
                self._endArticle()
                articleTag = 'article'
                if self._context.outputFmt != 'epub':
                    articleTag = 'div'
                self._writeHtml('\n<%s class="glossary-entry">\n<dfn>' % articleTag)
                self._inArticle = True
                self._inDfn = True
                    
        elif name == 'title':
            self._endArticle()
            titleType = self._getAttributeValue(attrs,'type')
            if titleType == 'runningHead':
                self._inTitle = True
                self._ignoreTitle = True
            elif titleType == 'x-chapterLabel':
                if not self._glossTitleWritten:
                    self._writeDefaultTitle()
                self._inTitle = True
                self._inChapterTitle = True
                self._titleText = ''
            else:
                if not self._glossTitleWritten:
                    self._titleTag = '<h%d>' % self._context.topHeaderLevel
                else:
                    level = self._getAttributeValue(attrs,'level')
                    if level is not None:
                        headerLevel = int(level) + self._context.topHeaderLevel
                    else:
                        headerLevel = self._defaultHeaderLevel
                    subType = self._getAttributeValue(attrs,'subType')
                    if subType is not None:
                        self._titleTag = '<h%d class="%s">' % (headerLevel, subType)
                    else:
                        self._titleTag = '<h%d>' % (headerLevel)
                self._inTitle = True
                self._titleText = ''
                    
        else:
            OsisHandler._processBodyTag(self, name, attrs)
                

    def _writeDefaultTitle(self):
        titleHtml = '<h%d>%s</h%d>' % (self._context.topHeaderLevel, self._context.config.glossaryTitle, self._context.topHeaderLevel)
        self._htmlWriter.write(titleHtml)
        self._glossTitleWritten = True
        self._breakCount = 2
        
    def _endArticle(self):
        if self._inArticle:
            if self._context.outputFmt == 'epub':
                self._writeHtml('\n</article>')
            else:
                self._writeHtml('\n</div>')
            self._inArticle = False
            