# SimpleSnippets.vim

Simple snippets is a simple snippet manager for Vim and NeoVim, based on standard
editor features, designed to be fast and lightweight. It integrates with Deoplete
to provide available snippets in popup menu and provides basic support of
snippet feature to Vim.

![simplesnippets](https://user-images.githubusercontent.com/19470159/39535519-c4904d2a-4e3c-11e8-9e1c-9796515f1913.gif)

This plugin was inspired by other snippet managers, like UltiSnips, snipMate,
Neosnippets, etc. However it has major differences in implementation, and
features it provides.

## Installation

Assuming you are using Vundle, place this in your .vimrc:

```vim
Plugin 'andreyorst/SimpleSnippets.vim'
```

Then run the following in Vim:

```vim
:source %
:PluginInstall
```

You're ready to use SimpleSnippets. However SimpleSnippets.vim doesn't come with snippets within it.
Snippets can be installed with [SimpleSnippets-snippets](https://github.com/andreyorst/SimpleSnippets-snippets) plugin.
It's not full featured collections of snippets for now, but I will extend it over time. Help is always appreciated.

If you want to redefine keys, consider adding this:
```vim
let g:SimpleSnippetsExpandOrJumpTrigger = "<Tab>"
let g:SimpleSnippetsJumpBackwardTrigger = "<S-Tab>"
let g:SimpleSnippetsJumpToLastTrigger = "<S-j>"
```
to your vimrc. If you want to disable default mappings, to write your own using functions, append `let g:SimpleSnippets_dont_remap_tab = 1` to those settings. For other settings please read the documentation.

## Why?

Back in the days I didn't use snippets at all. Because, I thought, that I don't
need them at all. The idea was that it is not that big difference in time spent on typing
everything by hands, and I was lazy to figure out how to setup and use snippet managers.

But then I've watched [this amazing talk](https://www.youtube.com/watch?v=XA2WjJbmmoM&t=2300s) about how to do most of your things without plugins. I was inspired with snippets, that can be created with abbreviations, and I've started experimenting.

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

(which generates getter and setter methods for current private variable under cursor in current class)

I've even made some placeholder support with mappings, so I could jump to snippet
body and edit things:

```vim
inoremap <silent><c-j> <Esc>:set nohlsearch<Cr>/\v\$\{[0-9]+:.*\}<Cr>msdf:f}:set hlsearch<Cr>:noh<Cr>i<Del><Esc>me`sv`e<c-g>
nnoremap <silent><c-j> <Esc>:set nohlsearch<Cr>/\v\$\{[0-9]+:.*\}<Cr>msdf:f}:set hlsearch<Cr>:noh<Cr>i<Del><Esc>me`sv`e<c-g>
```

I highly recommend you go through this yourselves, as it boosts your Vim's
movement knowledge beyond the limitations of any emacs user. But again, I decided
to try snippet managers. I've tried many, and sticked with Ultisnips. It is great
plugin, and I highly recommend you use it, if you're using Vim (ultisnips works
in NeoVim too, but it is not supported officially), and you have rather powerful
machine, because ultisnips requires some resources, wich in my case was performance
killer on my GPD Pocket, and Nexus 5x (yes I use NeoVim on my smartphone a lot).

So I've decided to try other plugins, but some of them were poor for functional,
some were even slower, and some lacked functions to use in my mappings.

I like the idea of single key for multiple things, wich is my case is <kbd>Tab</kbd>.
I use <kbd>Tab</kbd> to scroll through auto completion popup, provided by Deoplete,
to expand snippets, provided by UltiSnips, and to jump between placeholders in
the snippet body. I wasn't able to setup snipMate to such configuration, and it
still was not that fast as I needed, and It needs two extra plugins, so I've
decided:

> If I was able to use such abbreviation snippets for a long time, maybe I should just create a snippet manager for them?

Bang! The first thing I thought of is to create function that will parse my snippet,
remove placeholder markers, and somehow let me jump on them. Some days after, I've
started working on this plugin and here it is.

## But!

You may think that there are already plenty of other snippet managers, and you may noticed
that I've said, that I've made it with just Vim's native features, wich means
that it should have lot of limitations, and will have even poorer functional then
other plugins?

The answer is... Yes. It has _some_ limitations, and far less functions, than other
snippet managers. It's main feature is speed. It provides **basic**
snippet support to Vim. Which means that you can expand, jump, mirror, use shell
commands, and there is even a small interface which other plugins can use to integrate with SimpleSnippets.

I may extend the functionality of this plugin in the future, if I figure out how, to
implement things in better way, without using third party plugins, or other
languages.

#### List Of Limitations
Here I'll try to list all limitations that you may encounter when using Simple Snippets:

- [ ] No tabstops.  
Why? Well, jumping is based on text searching. Because placeholders are deleted from snippet body when it is pasted to your file there is no way to find empty ones, because text behind them for example may change. If NeoVim will add ability to use multicursor and position it in text like in other modern editors this may be implemented. Because of this limitation mirroring is done differently too.
- [ ] Placeholders have slightly different syntax than other plugins use.  
SimpleSnippets supports normal: `${1:text}`, command: `${2!command}`, and repeater `$3` placeholders.
- [ ] Normal placeholders should contain per snippet unique bodies.  
So you can't use `${2:text_a} ${0:text_b} ${1:text_a}` constructions. SimpleSnippets will jump to first match of `text_a` in snippet body. This is major limitation.
- [ ] Jumping is based on searching for a string.  
As was already said before. So if you replace some part of snippets in the same way, how your next placeholder is defined, you may jump to it instead of that placeholder.
- [ ] Single snippet editing at time.
If you expanded a snippet, and you try to expand snippet inside this one, you will lose ability to jump in your previous snippet.
- [ ] No nested placeholders.
- There may be more, which I've not thought about.

**Withdrawn limitations:**
- [x] Every snippet **must** contain zero indexed placeholder, aka `${0:text}`
- [x] Command placeholders, that output is more then single line can't be jumped.
- [x] Trigger must be separated from everything
- [x] No back jumping.

After reading this list you may want to ask me this question:

## Why would I even may want to use it?

You probably won't! I understand this, because I've developed it for myself in first place, and I can obey these restrictions and limitations because I need simple snippets and fast plugin for them.
I know that having an advanced, full-featured, complex solution is great, because of powers, that you gain form it.
However often too powerful tool need a powerful hardware to run smoothly.
If you feel that other snippet solutions are making your Vim slow,
then you probably may want to use it.

This plugin is fast. It is lightweight, and can be used on phones, netbooks, slow
PCs, via ssh, and maybe in more cases, which I've not thought about for now. And there was
a reason to call it _SimpleSnippets_, you know.

If after reading this you still want to try it out, you re welcome to!
This plugin is not that bad, however you may think of it. Please read the documentation
provided with the plugins to understand how things work. If you encounter any problem
[feel free to file an Issue](https://github.com/andreyorst/SimpleSnippets.vim/issues/new)

## Some SimpleSnippets action gifs

#### Deoplete completion popup

![compmenu](https://user-images.githubusercontent.com/19470159/39534438-416411e0-4e3a-11e8-8b15-ae9d27c7f672.gif)

#### Adding a snippet:

![adding a snippet](https://user-images.githubusercontent.com/19470159/39096706-36884290-465c-11e8-9177-d1407ff26f43.gif)

#### Adding a Flash snippet:

![adding flash snippet](https://user-images.githubusercontent.com/19470159/39096497-87df33b8-4659-11e8-9f10-2f7590f90987.gif)

#### Shell and plain text snippets:

![shell and plain text](https://user-images.githubusercontent.com/19470159/39097254-8cbc957a-4662-11e8-841b-65d239551517.gif)
![viml and shell](https://user-images.githubusercontent.com/19470159/39826577-d4f29124-53bd-11e8-812c-07c160e84298.gif)

#### Jumping back and forth

![backjumping](https://user-images.githubusercontent.com/19470159/40218859-b84e4c06-5a7b-11e8-8841-95ccbf45636f.gif)
