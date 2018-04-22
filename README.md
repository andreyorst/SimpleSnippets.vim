# SimpleSnippets.vim

Simple snippets is a simple snippet manager for Vim and NeoVim, based on standard
editor features, designed to be fast and lightweight. It provides basic support of
snippet feature to vim.

![simplesnippets](https://user-images.githubusercontent.com/19470159/39096685-103d060c-465c-11e8-8b52-a61ff37d7564.gif)

This plugin was inspired by other snippet managers, like UltiSnips, snipMate,
Neosnippets, and others. However it has major differences in implementation, and
features it provides.

## Installation

Assuming you using Vundle, place this in your .vimrc:

```vim
Plugin 'andreyorst/SimpleSnippets.vim'
```

Then run the following in Vim:

```vim
:source %
:PluginInstall
```

You re redy to use SimpleSnippets. However SimpleSnippets.vim doesn't come with snippets.
You should define it by yourselves for now. I'm planning to release separate plugin
with snippets only.

## Why?

Back in the days I didn't used snippets at all. Because, I thought, that I don't
need them at all. I thought that it is not big difference in time spent on typing
everything by myself, and not figuring out how to setup and use snippet managers.

But then I've watched [this amasing talk](https://www.youtube.com/watch?v=XA2WjJbmmoM&t=937s) about how to do most of your thinks without
plugins. I was inspired with snippets, that can be created with abbreviations,
and I've started experimenting.

First approach was something like this:

```vim
iabbr class/ <Esc>:-1read $HOME/.vim/snippets/class<CR><Esc>/_Class_Name_<CR>:noh<CR>:%s//g<left><left>
```
Which read my file with class template to current file, and started a substitute
command, where I was able to define class name. But then I needed to go to class
body by myself, but even so, I've noticed how easer it to type single word,
expand it and then just edit the rest.

Days passed, I've defined bunch of this abbreviations. It was very fun to create
this abbreviations, and confuse people with such "magic" ones:

```vim
autocmd FileType cpp,h,hpp nnoremap <F3> <Esc>0:set nohlsearch<CR>/;<CR>y^?private<CR>:-1read $HOME/.vim/snippets/getSet.cpp<CR>0Pa()<Esc>bbyw~hiobtain<Esc>/;<CR>P:noh<CR>==j0==/)<CR>bPnbb~hiestablish<Esc>nPnb~/ =<CR>P/;<CR>Pnb~?obtain<CR>y^j/(<CR>p^:set hlsearch<CR>:noh<CR>
```

(which generates getter and setter methods for current private variable under cursot in current class)

I've even made some placeholder support with mappings, so I could jump to snippet
body and edit things:

```vim
inoremap <silent><c-j> <Esc>:set nohlsearch<Cr>/\v\$\{[0-9]+:.*\}<Cr>msdf:f}:set hlsearch<Cr>:noh<Cr>i<Del><Esc>me`sv`e<c-g>
nnoremap <silent><c-j> <Esc>:set nohlsearch<Cr>/\v\$\{[0-9]+:.*\}<Cr>msdf:f}:set hlsearch<Cr>:noh<Cr>i<Del><Esc>me`sv`e<c-g>
```

I highly recommend to went through this by yourselves, it boost's your Vim's
movement knowledge beyond the limitations of any emacs user. But again, I decided
to try snippet managers. I've tried many, and sticked with Ultisnips. It is great
plugin, and I highly recommend you to use it, if you're using Vim (ultisnips works
in neovim too, but it is not supported officially), and you have rather powerfull
machine, because ultisnips requires some resources and in my case it was performance
killer on my GPD Pocket, and Nexus 5x (yes I use neovim on my smartpfone a lot).

So I've decided to try other plugins, but some of them were poor for functional,
some were even slower, and some lacked functions to use in my mappings.

I like the idea of single key for multiple things, wich is my case is <kbd>Tab</kbd>.
I use <kbd>Tab</kbd> to scroll through autocompletion popup, provided by Deoplete,
to expand snippets, provided by UltiSnips, and to jump between placeholders in
the snippet body. I wasn't able to setup snipMate to such configuration, and it
still was not that fast as I needed, and It needs two extra plugins, so I've
decided:

> If I was able to use such abbreviation snippets for a long time, maybe I should just create a snippet manager for them?

Bang! The first thing I thought of is to create function that will parse my snippet,
remove placeholder markers, and somehow let me jump on them. Some days after, I've
started working on this plugin and here it is.

## But!

You may think that there are already some snippet managers, and you may noticed
that I've said, that I've made it with just vim's native features, wich means
that it should have lot of limitations, and will have even poorer functional then
other plugins?

The answer is... Yes. It has limitations, and far less functions, than other
snippet managers. It's main feature is speed, and lightweight. It provides **basic**
snippet support to Vim. Which means that you can expand, jump, mirror, use shell
commands, and there is even a small interface to integrate with completion and
LSP plugins.

I may extend the functionality of a plugin in the future, if I figure out how, to
implement things in better way, without using third party plugins, or other
languages.

### List Of Limitations

- No tabstops.
- Placeholders have slightly different syntax than other plugins use.
- Normal placeholders should contain per snippet unique bodies.
- Mirror placeholders are based on substitution over snippet body.
- Normal placeholders can't have same body as mirror placeholders.
- Shell placeholders, that output is more then single line can't be jumped
- Every snippet **must** contain zero indexed placeholder, aka `${0:text}`
- Jumping is based on searching for a string, so if you replace some part in the same way, how your next placeholder is defined, you may jump to it instead of that placeholder.
- There may be more, which I've not thought about.

## Why do I even may want to use it?

You probably won't! I know that having a great advanced solution is great.
However often too powerful tool need a powerful hardware to run smoosely.
If you feel that other snippet solutions are making your Vim slow,
then you probably may want to use it.

This plugin is fast. It is lightweight, and can be used on phones, netbooks, slow
PCs, via ssh, and maybe in more cases, wich I've not thought about now. There was
a reason to call it _SimpleSnippets_, you know.

If after reading this you're still want to try it out, you re welcome to!
This plugin is not that bad, how you may think of it. Please read the documentation
provided with the plugins to understand how things work. If you encounter any problem
feel free to open an Issue at https://github.com/andreyorst/SimpleSnippets.vim/issues/new

## Some SimpleSnippets action gifs

#### Adding a snippet:

![adding a snippet](https://user-images.githubusercontent.com/19470159/39096706-36884290-465c-11e8-9177-d1407ff26f43.gif)

#### Adding a Flash snippet:

![adding flash snippet](https://user-images.githubusercontent.com/19470159/39096497-87df33b8-4659-11e8-9f10-2f7590f90987.gif)

