# SimpleSnippets.vim  
[![GitHub release](https://img.shields.io/github/release/andreyorst/simplesnippets.vim.svg)](https://github.com/andreyorst/SimpleSnippets.vim/releases)
[![GitHub Release Date](https://img.shields.io/github/release-date/andreyorst/SimpleSnippets.vim.svg)](https://github.com/andreyorst/SimpleSnippets.vim/releases)
![Github commits (since latest release)](https://img.shields.io/github/commits-since/andreyorst/Simplesnippets.vim/latest.svg)
![license](https://img.shields.io/github/license/andreyorst/simplesnippets.vim.svg)

[SimpleSnippets.vim](https://github.com/andreyorst/SimpleSnippets.vim) is a simple snippet manager for Vim and NeoVim, based on standard
editor features, designed to be fast and lightweight. It integrates with Deoplete
to provide available snippets in popup menu and provides basic support of
snippet features to Vim and NeoVim.

![simplesnippets](https://user-images.githubusercontent.com/19470159/39535519-c4904d2a-4e3c-11e8-9e1c-9796515f1913.gif)

This plugin was inspired by other snippet managers, like UltiSnips, snipMate,
Neosnippets, etc. However it has major differences in implementation, and
features it provides.

## Installation  
Assuming you are using vim-plug, place this in your .vimrc:

```vim
Plug 'andreyorst/SimpleSnippets.vim'
```

Then run the following in Vim:

```vim
:so % | PlugInstall
```

And you're ready to go. However SimpleSnippets.vim doesn't come with snippets within it.
Snippets can be installed with [SimpleSnippets-snippets](https://github.com/andreyorst/SimpleSnippets-snippets) plugin.
It's not full featured collections of snippets for now, but I will extend it over time. Help is always appreciated.

## Configuration tips  
If you satisfied with default snippet behavior but want to change the keys needed to invoke snippet actions, consider adding these variables to your `.vimrc` or `init.vim`:
```vim
let g:SimpleSnippetsExpandOrJumpTrigger = "<Tab>"
let g:SimpleSnippetsJumpBackwardTrigger = "<S-Tab>"
let g:SimpleSnippetsJumpToLastTrigger = "<C-j>"
```
However, If you want to create your own mappings, for example to use your own using functions around plugin's ones, append `let g:SimpleSnippets_dont_remap_tab = 1` to those settings.

If you want a horizontal split while editing a snippet, instead of vertical one, add `let g:SimpleSnippets_split_horizontal = 1` to your `.vimrc` or `init.vim`.

SimpleSnippets.vim comes with a comprehensive [documentation](https://github.com/andreyorst/SimpleSnippets.vim/blob/master/doc/SimpleSnippets.txt), please refer to It for extra configuration tips, and general information.

## Syntax  
SimpleSnippets supports these kinds of placeholders:  
- `$1` or `${1}` or `${1:}` - tabstops  
  Any of syntaxes above can be used for tabstops. SimpleSnippets-snippets uses the `$1` one.
- `${1:text}` - normal placeholder  
  You can use nested placeholders like `${2:text ${1:other text}}`, however if you modify nested placeholder beyond its boundaries it will be dropped and parent placeholder will include nested ones contents.
- `${2:text} $2` - mirroring  
  Mirroring works just like in other plugins like UltiSnips.
- `${3|option1, option2|}` - choice placeholder  
  Choice placeholder lets you choose the candidate, or write your own instead. By default none is selected.
- `${4!echo "shell or viml"}` - command placeholder  
  Command placeholder can execute shell, or vimscript commands, which can be echoed.

For the information about missing types of placeholders please check [limitations section](https://github.com/andreyorst/SimpleSnippets.vim#list-of-limitations--design-flaws)

## Design choices  
- This plugin was designed in pure Vimscript.  
  This is done because the main goal was the speed and lightweight of the plugin so it could run on slow devices, like Android phone, with Vim running within Termux.
- Snippets are stored separately per file.  
  This is mainly done to make it easy to maintain updates of snippet files.
- Snippet is being parsed after insertion to the buffer
  This makes possible to handle nested placeholders with default `%` motion. So if anything will go wrong you will end up with unparsed snippet.

Because of using a viml as a main language, and not using any external libraries there are some design flaws and limitations that I'm currently trying to withdrawn:

### List of limitations/design flaws  
- [ ] Adding lines before snippet breaks jumping
- [ ] Commands that result multiline output can't be jumped.
- [ ] Single snippet editing at time.  
  If you expanded a snippet, and you try to expand snippet inside this one, you will lose ability to jump in your previous snippet.
- There may be more, which I've not thought about.

So if any of those limitations above are critical to you, consider using another snippet manager.
However if you still want to use it, consider reading the documentation, and if you encounter any problem, or want to propose a feature [feel free to file an Issue](https://github.com/andreyorst/SimpleSnippets.vim/issues/new)

I've already did some improvements in the core and will continue to work on the plugin to withdrawn every limitation that I can.  
There is a list of Withdrawn limitations:
- [x] Every snippet **must** contain zero indexed placeholder, aka `${0:text}`
- [x] Trigger must be separated from everything
- [x] No back jumping.
- [x] Placeholders must be separated from each other and another text.
- [x] Placeholders have slightly different syntax than other plugins use.
- [x] No tabstops.
- [x] Normal placeholders should contain per snippet unique bodies.  
- [x] Jumping is based on searching for a string.  
- [x] No nested placeholders.

## About  
[SimpleSnippets.vim](https://github.com/andreyorst/SimpleSnippets.vim) was created and being maintained by [@andreyorst](https://github.com/andreyorst). It is being tested against Vim 8.1, and NeoVim 0.3.\*. Other versions are not officially supported, but might work. If you found an issue, or want to propose a change, you're welcome to do so at SimpleSnippets.vim GitHub repository: https://github.com/andreyorst/SimpleSnippets.vim

### Demostration gifs

**Deoplete completion popup:**  
![compmenu](https://user-images.githubusercontent.com/19470159/39534438-416411e0-4e3a-11e8-8b15-ae9d27c7f672.gif)

**Adding a snippet:**  
![adding a snippet](https://user-images.githubusercontent.com/19470159/39096706-36884290-465c-11e8-9177-d1407ff26f43.gif)

**Adding a Flash snippet:**  
![adding flash snippet](https://user-images.githubusercontent.com/19470159/39096497-87df33b8-4659-11e8-9f10-2f7590f90987.gif)

**Shell and plain text snippets:**  
![shell and plain text](https://user-images.githubusercontent.com/19470159/39097254-8cbc957a-4662-11e8-841b-65d239551517.gif)
![viml and shell](https://user-images.githubusercontent.com/19470159/39826577-d4f29124-53bd-11e8-812c-07c160e84298.gif)

**Jumping back and forth:**  
![backjumping](https://user-images.githubusercontent.com/19470159/40218859-b84e4c06-5a7b-11e8-8841-95ccbf45636f.gif)

**Choice placeholders:**  
![choice](https://user-images.githubusercontent.com/19470159/40890243-b9e65e98-677b-11e8-958f-a36c7da58251.gif)
 
