#!/usr/bin/perl

use strict;
use warnings;
use ShionBackup;
use ShionBackup::Logger;

$ShionBackup::USAGE = \*DATA;
eval {
    ShionBackup->run(@ARGV);
};
if ($@) {
    FATAL $@;
    die $@;
}

__DATA__

=encoding utf-8

=head1 NAME

shion-backup

=head1 SYNOPSYS

 $ shion-backup OPTIONS CONFIGFILE...

=head1 DESCRIPTION

shion-backup は、YAML 形式で記述された設定ファイル I<CONFIGFILE> の指定
に従いバックアップを取得し、リモートのストレージにアップロードする。

I<CONFIGFILE> が複数指定された場合は、先頭から順に読み込まれ、以下の規
則でマージされる。

=over 4

=item *

型が違う場合、後の内容で上書きされる

=item *

共に配列型の場合、後の内容が後ろに追加される。

=item *

共に連想配列型同士の場合、各キー毎に前述の規則が適用される。

=item *

上記以外の場合は、後の内容で上書きされる。

=back

=head1 OPTIONS

=over 4

=item B<--help>, B<-h>

このヘルプを表示する。

=item B<--dump-target>, B<--dump>, B<-d>

展開済みターゲット設定を表示する。

=item B<--dump-config>

読み込まれたマージ済み設定ファイルを表示する。

=item B<--workfile>=FILE, B<-w> FILE

バックアップ時の中間生成ファイルを指定する。

=item B<--noupload>

バックアップを取得するがアップロードしない。

=item B<--progress>

アップロード時にプログレスバーを表示する。

=item B<--debug>

デバッグ表示を行う。

=back

=head1 CONFIG FILE STRUCTURE

設定ファイルは、定められた構造規則に従っていなければならない。

設定ファイルが複数に分割されている場合は、すべてのマージが行われた後に
構造規則に従っていればよい。

=head2 ルート構造

 %config := (
   'uploader' => %uploader,
   'template' => %templates,
   'target'   => @targets
 )

=head2 アップローダ設定

 %uploader := (
   'id'     => $id,
   'secret' => $secret,
   'url'    => $url,
 )

=over 4

=item $url

アップロード先のベースURL

=back

=head2 テンプレート設定

 %templates := (
   NAME => (
     'template' => ~ | $template_name | @template_name,
     *
   ),
   ...
 )

=over 4

=item I<NAME>

テンプレート名

=item $template_name, @templare_name

ベースとするテンプレート名。

=back

=head2 ターゲット設定

 @targets := (
   %target,
   ...
 )

 %target := (
   'filename'   => $filename,
   'uploadsize' => ~ | $uploadsize,
   'arg'        => ~ | %arg,
   'template'   => ~ | $template_name | @template_name,
   'command'    => ~ | @command,
 )

 @command := (
   $command | &command,
   ...
 )

=over 4

=item $filename

アップロードするファイル名。

C<設定{uploader}{url}> からの相対パスを指定する。

=item $uploadsize

一度にアップロードされるファイルサイズの目安で単位は MB。

アップロード前に生成される中間ファイルのサイズは、この値に近いものとな
る。この中間ファイルは、アップロード後削除されるため、一連の動作で消費
されるディスクスペースは、最大でこのサイズに近いものとなる。

=item %arg

引数展開に用いられる任意の値を指定する。

大文字と0個以上のアンダースコアで指定されるキーは、予約されている。

=item $template_name, @template_name

ベースとするテンプレート名。

深さ優先でマージされる。

=item $command

実行するコマンド。system 関数により実行される。

実行時の標準入出力は、それぞれ前後のコマンドに接続される。

ただし、C<@command[0]> の標準入力はクローズされる。また、
C<@command[-1]> の標準出力は、アップロードを行うプロセスに接続される。

=item &command

実行するコマンド。perl の関数として実行される。

第１引数には、C<\%arg> が渡される。

標準入出力の扱いは、$command に同じ。

=back

=head1 変数展開

C<$command> の値は、C<%arg> の値を用いて変数展開される。

=over 4

=item ${$}

"$" に変換される。

=item ${I<NAME>:<I<STRING>}

"C<I<STRING>>C<$arg{I<NAME>}>" に変換される。

=item ${I<NAME>:>I<STRING>}

"C<$arg{I<NAME>}>C<I<STRING>>" に変換される。

=item ${I<NAME>}

"C<$arg{I<NAME>}>" に変換される。

=back

=head1 定義済み変数

C<%arg> の以下のキーは、特定の目的で使用される。

=over 4

=item S3_RRS

値が真の場合、Reduced Redundancy Storage を使用する。

=back

=head1 NOTE

C<$uploadsize> が指定されている場合、バックアップの取得に長時間かかる場合
がある。

=head1 AUTHOR

YAMAMOTO, N. <nym at nym.jp>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011-2012 YAMAMOTO, N. <nym at nym.jp>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
