#
# 三軒茶屋１丁目のゴミ出し日ボット
# Perlの練習がてら作成
#

use strict;
use warnings;
use utf8;
use Net::Twitter::Lite;
use YAML::Tiny;
use YAML;
use Time::Piece;
use Time::Seconds; # 日時の加減算に使用
use POSIX;

# Twitter OAuth
sub oauth {
  my $API_BASE_URL = 'http://api.twitter.com/1.1';
  my $CONFIG = YAML::LoadFile('config.yaml');

  # Twitter API 1.1 対応
  my %opts = (
    apiurl                => $API_BASE_URL,
    searchapiurl          => $API_BASE_URL . '/search',
    search_trends_api_url => $API_BASE_URL,
    lists_api_url         => $API_BASE_URL,
    consumer_key          => $CONFIG->{consumer_key},
    consumer_secret       => $CONFIG->{consumer_secret},
  );

  # constructs a "Net::Twitter::Lite" object
  my $t = Net::Twitter::Lite->new(%opts);

  # トークンをセットする
  $t->access_token($CONFIG->{access_token});
  $t->access_token_secret($CONFIG->{access_token_secret});

  return $t;
}

# 何ゴミの日かを判定
sub nanigomi {
  my %GOMI_NO_HI = (
    '月' => '可燃ごみ',
    '火' => ['ペットボトル', '不燃ごみ', 'ペットボトル', '不燃ごみ'], # 配列への参照が代入される
    '木' => '可燃ごみ',
    '金' => '資源ごみ（古紙、ガラスびん、缶）',
  );

  my $time;
  if ($_[0] eq 'today') {
    $time = localtime();
  } elsif ($_[0] eq 'tomorrow') {
    $time = localtime() + ONE_DAY;
  } else {
    return 0;
  }

  my $day_num = $time->mday; # x日
  my @day_names = qw/日 月 火 水 木 金 土/;
  my $day_name = $time->wdayname(@day_names); # y曜日

  my $gomi = $GOMI_NO_HI{$day_name};

  if (ref($gomi) eq "ARRAY") { # 火曜
    my $day_count_in_month = ceil($day_num / 7); # その曜日が当月の何回目か
    $gomi = $gomi->[$day_count_in_month-1]; # $gomiは配列への参照なので->で参照先を取得
  }

  return $gomi;
}

sub when_jpn {
  if ($_[0] eq 'today') {
    return "今日";
  } elsif ($_[0] eq 'tomorrow') {
    return "明日";
  } else {
    return 0;
  }
}

sub add_space {
  my $msg = $_[0];
  my $hour = localtime()->hour;
  return $msg . '　' x $hour;
}


# メイン
if (@ARGV == 1) {
  my $when = $ARGV[0]; # today or tomorrow
  my $tw = &oauth;
  my $gomi = &nanigomi($when);

  if ($gomi) {
    # 投稿
    my $when_jpn = &when_jpn($when);
    my $message = "${when_jpn}は「${gomi}」の日です。ごみ出しは朝８時までに。";
    my $status = $tw->update({ status => &add_space($message) });
    #print YAML::Dump($status);
  }
} else {
  print "\$ARGV[0] is required.\n";
}
