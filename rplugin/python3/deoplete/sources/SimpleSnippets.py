from .base import Base

class Source(Base):
    def __init__(self, vim):
        Base.__init__(self, vim)

        self.name = 'SimpleSnippets'
        self.mark = '[SS]'
        self.rank = 8
        self.is_volatile = True

    def gather_candidates(self, context):
        suggestions = []
        snippets = self.vim.eval(
            'SimpleSnippets#availableSnippets()')
        for trigger in snippets:
            suggestions.append({
                'word': trigger[0],
                'menu': trigger[1],
                'dup': 1
            })
        return suggestions
