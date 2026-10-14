<#
.SYNOPSIS
    Interactive Windows GUI Dialog to pick Git Identity (Personal vs Work).
.DESCRIPTION
    Presents a sleek modern WPF dialog to select between Personal (GitHub) and Work (Azure DevOps / Microsoft).
    Configures repository local git config with the selected identity.
#>
param (
    [string]$RepoPath = (Get-Location).Path,
    [string]$RemoteUrl = "",
    [string]$ConfigFilePath = ""
)

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Drawing

# Determine default config file location if not specified
if ([string]::IsNullOrWhiteSpace($ConfigFilePath)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ConfigFilePath = Join-Path $scriptDir "config.json"
    if (-not (Test-Path $ConfigFilePath)) {
        $examplePath = Join-Path $scriptDir "config.example.json"
        if (Test-Path $examplePath) {
            $ConfigFilePath = $examplePath
        }
    }
}

# Default profiles if config not found
$config = @{
    personal = @{
        name = "Personal Account"
        email = ""
        label = "Personal (GitHub)"
        domains = @("github.com")
    }
    work = @{
        name = "Work Account"
        email = ""
        label = "Work (Azure DevOps / Microsoft)"
        domains = @("dev.azure.com", "visualstudio.com")
    }
}

if (Test-Path $ConfigFilePath) {
    try {
        $loadedConfig = Get-Content $ConfigFilePath -Raw | ConvertFrom-Json
        if ($loadedConfig.personal) {
            $config.personal.name = $loadedConfig.personal.name
            $config.personal.email = $loadedConfig.personal.email
        }
        if ($loadedConfig.work) {
            $config.work.name = $loadedConfig.work.name
            $config.work.email = $loadedConfig.work.email
        }
    } catch {
        Write-Warning "Could not parse $ConfigFilePath, using defaults."
    }
}

# Determine suggestion based on remote URL
$suggested = "personal"
if ($RemoteUrl -match "dev\.azure\.com|visualstudio\.com") {
    $suggested = "work"
} elseif ($RemoteUrl -match "github\.com") {
    $suggested = "personal"
}

# Build XAML UI with modern sleek dark theme
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Git Identity Selector" Height="460" Width="520"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#18181b" Foreground="#f4f4f5" FontFamily="Segoe UI"
        WindowStyle="None" AllowsTransparency="True" BorderBrush="#3f3f46" BorderThickness="1">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Name="border" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Opacity" Value="0.9"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Opacity" Value="0.75"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Grid.Row="0">
            <TextBlock Text="Select Git Account" FontSize="20" FontWeight="Bold" Foreground="#ffffff"/>
            <TextBlock Text="Choose which profile to use for commits &amp; pushes in this repository." FontSize="12" Foreground="#a1a1aa" Margin="0,4,0,0"/>
        </StackPanel>

        <!-- Remote info pill -->
        <Border Grid.Row="1" Background="#27272a" CornerRadius="6" Padding="10,8" Margin="0,16,0,16">
            <StackPanel Orientation="Vertical">
                <TextBlock Text="TARGET REMOTE" FontSize="10" FontWeight="SemiBold" Foreground="#71717a"/>
                <TextBlock Name="TxtRemote" Text="$RemoteUrl" FontSize="12" Foreground="#38bdf8" TextTrimming="CharacterEllipsis"/>
            </StackPanel>
        </Border>

        <!-- Account Cards -->
        <StackPanel Grid.Row="2">
            <!-- Personal Option Card -->
            <Border Name="CardPersonal" Background="#27272a" BorderBrush="#3f3f46" BorderThickness="2" CornerRadius="8" Padding="14" Margin="0,0,0,12" Cursor="Hand">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <RadioButton Name="RbPersonal" Grid.Column="0" VerticalAlignment="Center" Margin="0,0,12,0"/>
                    <StackPanel Grid.Column="1">
                        <TextBlock Text="Personal Account (GitHub)" FontSize="14" FontWeight="SemiBold" Foreground="#ffffff"/>
                        <TextBlock Name="TxtPersonalDetail" Text="Email: ranjan.viper@outlook.com" FontSize="11" Foreground="#a1a1aa" Margin="0,2,0,0"/>
                    </StackPanel>
                    <Border Name="BadgePersonal" Grid.Column="2" Background="#065f46" CornerRadius="4" Padding="6,2" Visibility="Collapsed">
                        <TextBlock Text="Recommended" FontSize="10" FontWeight="SemiBold" Foreground="#34d399"/>
                    </Border>
                </Grid>
            </Border>

            <!-- Work Option Card -->
            <Border Name="CardWork" Background="#27272a" BorderBrush="#3f3f46" BorderThickness="2" CornerRadius="8" Padding="14" Cursor="Hand">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <RadioButton Name="RbWork" Grid.Column="0" VerticalAlignment="Center" Margin="0,0,12,0"/>
                    <StackPanel Grid.Column="1">
                        <TextBlock Text="Work Account (Azure DevOps / Microsoft)" FontSize="14" FontWeight="SemiBold" Foreground="#ffffff"/>
                        <TextBlock Name="TxtWorkDetail" Text="Email: (Configured work email)" FontSize="11" Foreground="#a1a1aa" Margin="0,2,0,0"/>
                    </StackPanel>
                    <Border Name="BadgeWork" Grid.Column="2" Background="#1e3a8a" CornerRadius="4" Padding="6,2" Visibility="Collapsed">
                        <TextBlock Text="Recommended" FontSize="10" FontWeight="SemiBold" Foreground="#60a5fa"/>
                    </Border>
                </Grid>
            </Border>
        </StackPanel>

        <!-- Remember Choice Checkbox -->
        <CheckBox Name="ChkRemember" Grid.Row="3" IsChecked="True" Margin="2,14,0,16" Foreground="#d4d4d8" FontSize="12">
            Remember this choice in local repository config (.git/config)
        </CheckBox>

        <!-- Action Buttons -->
        <Grid Grid.Row="4">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="12"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Button Name="BtnCancel" Grid.Column="0" Content="Cancel Push" Background="#27272a" Foreground="#e4e4e7"
                    BorderBrush="#3f3f46" BorderThickness="1" Height="38" FontSize="13" FontWeight="SemiBold"/>
            <Button Name="BtnConfirm" Grid.Column="2" Content="Apply &amp; Continue" Background="#2563eb" Foreground="#ffffff"
                    BorderThickness="0" Height="38" FontSize="13" FontWeight="Bold"/>
        </Grid>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Element references
$txtRemote = $window.FindName("TxtRemote")
$txtPersonalDetail = $window.FindName("TxtPersonalDetail")
$txtWorkDetail = $window.FindName("TxtWorkDetail")
$rbPersonal = $window.FindName("RbPersonal")
$rbWork = $window.FindName("RbWork")
$badgePersonal = $window.FindName("BadgePersonal")
$badgeWork = $window.FindName("BadgeWork")
$cardPersonal = $window.FindName("CardPersonal")
$cardWork = $window.FindName("CardWork")
$chkRemember = $window.FindName("ChkRemember")
$btnConfirm = $window.FindName("BtnConfirm")
$btnCancel = $window.FindName("BtnCancel")

if (-not [string]::IsNullOrWhiteSpace($RemoteUrl)) {
    $txtRemote.Text = $RemoteUrl
} else {
    $txtRemote.Text = "(Local Repository - No Remote Configured)"
}

$personalEmail = if ($config.personal.email) { $config.personal.email } else { "Not set" }
$workEmail = if ($config.work.email) { $config.work.email } else { "Company Microsoft Account" }

$txtPersonalDetail.Text = "Name: $($config.personal.name) | Email: $personalEmail"
$txtWorkDetail.Text = "Name: $($config.work.name) | Email: $workEmail"

# Card click handlers
$cardPersonal.Add_MouseDown({
    $rbPersonal.IsChecked = $true
})
$cardWork.Add_MouseDown({
    $rbWork.IsChecked = $true
})

# Highlight recommended card
$brushDefaultBorder = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3f3f46")
$brushActiveBorder = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3b82f6")

$rbPersonal.Add_Checked({
    $cardPersonal.BorderBrush = $brushActiveBorder
    $cardWork.BorderBrush = $brushDefaultBorder
})
$rbWork.Add_Checked({
    $cardWork.BorderBrush = $brushActiveBorder
    $cardPersonal.BorderBrush = $brushDefaultBorder
})

if ($suggested -eq "work") {
    $rbWork.IsChecked = $true
    $badgeWork.Visibility = [System.Windows.Visibility]::Visible
    $cardWork.BorderBrush = $brushActiveBorder
} else {
    $rbPersonal.IsChecked = $true
    $badgePersonal.Visibility = [System.Windows.Visibility]::Visible
    $cardPersonal.BorderBrush = $brushActiveBorder
}

# Drag move on background
$window.Add_MouseLeftButtonDown({
    $window.DragMove()
})

$script:result = $null

$btnConfirm.Add_Click({
    $selectedAccount = if ($rbWork.IsChecked) { "work" } else { "personal" }
    $script:result = @{
        Status = "Approved"
        Account = $selectedAccount
        Remember = [bool]$chkRemember.IsChecked
        Profile = $config[$selectedAccount]
    }
    $window.Close()
})

$btnCancel.Add_Click({
    $script:result = @{
        Status = "Cancelled"
    }
    $window.Close()
})

# Show modal
$null = $window.ShowDialog()

if ($script:result -and $script:result.Status -eq "Approved") {
    $selected = $script:result.Account
    $profile = $script:result.Profile
    
    if ($script:result.Remember -and (Test-Path (Join-Path $RepoPath ".git"))) {
        # Configure local git
        git -C "$RepoPath" config --local user.account "$selected"
        if (-not [string]::IsNullOrWhiteSpace($profile.name)) {
            git -C "$RepoPath" config --local user.name "$($profile.name)"
        }
        if (-not [string]::IsNullOrWhiteSpace($profile.email)) {
            git -C "$RepoPath" config --local user.email "$($profile.email)"
        }
        
        # Configure credential helper specific behavior
        if ($selected -eq "work") {
            # Ensure dev.azure.com uses GCM
            git -C "$RepoPath" config --local credential.helper "manager"
        }
    }
    
    # Output result as JSON for callers/hooks
    $script:result | ConvertTo-Json -Compress
    exit 0
} else {
    # Cancelled or closed
    Write-Error "Git operation cancelled by user."
    exit 1
}
