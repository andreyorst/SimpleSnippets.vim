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
            'SimpleSnippets#core#getAvailableSnippetsDict()')
        for trigger in snippets:
            suggestions.append({
                'word': trigger,
                'menu': self.mark + ' ' + snippets.get(trigger, ''),
                'dup': 1
            })
        return suggestions
