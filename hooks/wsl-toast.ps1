param([string]$Message = "通知")

[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null

$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(
    [Windows.UI.Notifications.ToastTemplateType]::ToastText02
)
$template.GetElementsByTagName('text').Item(0).AppendChild($template.CreateTextNode('Claude Code')) | Out-Null
$template.GetElementsByTagName('text').Item(1).AppendChild($template.CreateTextNode($Message)) | Out-Null

$appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId)
$notifier.Show([Windows.UI.Notifications.ToastNotification]::new($template))
