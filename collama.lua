-- Collama; LLaMA 4 Hackathon Submission
-- This plugin generates Roblox UI elements using LLaMA's AI model.
-- Developed by: Mohammad Mendahawi, Sufyan Waryah, Abdul Mendahawi
local HttpService = game:GetService("HttpService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local GEMINI_API_KEY = "AIzaSyA1TY4WGcHi8ZdjMY1GsMO4SC_UUq3hk8o"
local GEMINI_API_URL =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" .. GEMINI_API_KEY

local pluginName = "Collama"
local pluginId = "CollamaPlugin"

-- --- THEME COLORS & SETTINGS ---
local THEME = {
    WidgetBackgroundColor = Color3.fromRGB(35, 35, 35),
    TextColorPrimary = Color3.fromRGB(230, 230, 230),
    TextColorSecondary = Color3.fromRGB(160, 160, 160),
    AccentColor = Color3.fromRGB(80, 80, 80),
    AccentTextColor = Color3.fromRGB(255, 255, 255),
    InputBackgroundColor = Color3.fromRGB(25, 25, 25),
    InputBorderColor = Color3.fromRGB(60, 60, 60),
    ButtonDisabledBackgroundColor = Color3.fromRGB(50, 50, 50),
    ButtonDisabledTextColor = Color3.fromRGB(110, 110, 110),
    CornerRadius = UDim.new(0, 0), -- Sharp corners
    FontRegular = Enum.Font.SourceSans,
    FontSemibold = Enum.Font.SourceSansSemibold,
    Padding = UDim.new(0, 10)
}
-- --- END THEME ---

-- Create Toolbar and Button
local toolbar = plugin:CreateToolbar(pluginName)
local button = toolbar:CreateButton(pluginName, "Generate UI with LlaMa AI", "rbxassetid://6538721725")

local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, true, -- Enabled
false, -- Floating
300, -- Width
400, -- Height
280, -- MinWidth
300 -- MinHeight
)

local widget = plugin:CreateDockWidgetPluginGui(pluginId, widgetInfo)
widget.Title = pluginName
widget.Enabled = false

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = THEME.WidgetBackgroundColor
mainFrame.BorderSizePixel = 0
mainFrame.Parent = widget

local padding = Instance.new("UIPadding")
padding.PaddingTop = THEME.Padding
padding.PaddingBottom = THEME.Padding
padding.PaddingLeft = THEME.Padding
padding.PaddingRight = THEME.Padding
padding.Parent = mainFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = THEME.Padding
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.FillDirection = Enum.FillDirection.Vertical
uiListLayout.Parent = mainFrame

-- Instruction Label
local instructionLabel = Instance.new("TextLabel")
instructionLabel.LayoutOrder = 1
instructionLabel.Text = "Describe the UI to generate:"
instructionLabel.Font = THEME.FontRegular
instructionLabel.TextColor3 = THEME.TextColorSecondary
instructionLabel.TextSize = 14
instructionLabel.TextWrapped = true
instructionLabel.TextXAlignment = Enum.TextXAlignment.Left
instructionLabel.BackgroundTransparency = 1
instructionLabel.Size = UDim2.new(1, 0, 0, 20)
instructionLabel.Parent = mainFrame

-- Prompt Input TextBox
local promptTextBox = Instance.new("TextBox")
promptTextBox.LayoutOrder = 2
promptTextBox.PlaceholderText = "e.g., a blue confirmation button..."
promptTextBox.PlaceholderColor3 = THEME.TextColorSecondary
promptTextBox.MultiLine = true
promptTextBox.TextWrapped = true
promptTextBox.ClearTextOnFocus = false
promptTextBox.Font = THEME.FontRegular
promptTextBox.TextColor3 = THEME.TextColorPrimary
promptTextBox.BackgroundColor3 = THEME.InputBackgroundColor
promptTextBox.BorderSizePixel = 1
promptTextBox.BorderColor3 = THEME.InputBorderColor
promptTextBox.Size = UDim2.new(1, 0, 0, 180) -- **FIX**: Changed to a fixed height for stability in UIListLayout
promptTextBox.TextSize = 14
promptTextBox.TextXAlignment = Enum.TextXAlignment.Left -- **FIX**: Explicitly align text to the left
promptTextBox.TextYAlignment = Enum.TextYAlignment.Top -- **FIX**: Explicitly align text to the top
promptTextBox.ClipsDescendants = true
promptTextBox.Parent = mainFrame

local promptCorner = Instance.new("UICorner")
promptCorner.CornerRadius = THEME.CornerRadius
promptCorner.Parent = promptTextBox

local textPadding = Instance.new("UIPadding")
textPadding.PaddingLeft = THEME.Padding
textPadding.PaddingRight = THEME.Padding
textPadding.PaddingTop = THEME.Padding
textPadding.PaddingBottom = THEME.Padding
textPadding.Parent = promptTextBox

-- Generate Button
local generateButton = Instance.new("TextButton")
generateButton.LayoutOrder = 3
generateButton.Text = "Generate"
generateButton.Font = THEME.FontSemibold
generateButton.TextColor3 = THEME.AccentTextColor
generateButton.BackgroundColor3 = THEME.AccentColor
generateButton.Size = UDim2.new(1, 0, 0, 38)
generateButton.TextSize = 16
generateButton.AutoButtonColor = true
generateButton.Parent = mainFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = THEME.CornerRadius
buttonCorner.Parent = generateButton

local originalButtonColor = generateButton.BackgroundColor3
local originalButtonText = generateButton.Text
local generatingButtonText = "Generating..."

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.LayoutOrder = 4
statusLabel.Text = "Ready."
statusLabel.Font = THEME.FontRegular
statusLabel.TextColor3 = THEME.TextColorSecondary
statusLabel.TextSize = 12
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.BackgroundTransparency = 1
statusLabel.Size = UDim2.new(1, 0, 0, 30)
statusLabel.Parent = mainFrame

-- Function to make the API call
local function generateCodeWithGemini(promptText)
    if GEMINI_API_KEY == "YOUR_GEMINI_API_KEY_HERE" or not GEMINI_API_KEY then
        statusLabel.Text = "Error: Please set your Gemini API Key in the plugin script."
        warn(pluginName .. ": API Key not set.")
        return nil
    end

    statusLabel.Text = "Preparing request..."
    generateButton.Active = false
    generateButton.BackgroundColor3 = THEME.ButtonDisabledBackgroundColor
    generateButton.TextColor3 = THEME.ButtonDisabledTextColor
    generateButton.Text = generatingButtonText

    local fullPrompt = table.concat(
        {"You are an expert Roblox Luau script generator. Your task is to generate only Luau code that creates UI elements in Roblox Studio.",
         "The generated code should be self-contained and create the UI elements directly.",
         "Assume the script will be parented to a suitable container (like a ScreenGui) by the plugin, so use 'script.Parent' to refer to this container.",
         "If the user asks for a 'ScreenGui', create one. Otherwise, create elements directly under 'script.Parent'.",
         "Do NOT include any markdown like ```lua or ```. Only output the raw Luau code.",
         "Ensure all created Instances have their Parent property set last, after all other properties.",
         "Use modern Roblox UI practices like UICorner where appropriate if the user implies a modern look.",
         "\nUser's request: " .. promptText}, "\n")

    local requestBody = {
        contents = {{
            parts = {{
                text = fullPrompt
            }}
        }},
        generationConfig = {
            temperature = 0.7,
            maxOutputTokens = 2048
        },
        safetySettings = {{
            category = "HARM_CATEGORY_HARASSMENT",
            threshold = "BLOCK_NONE"
        }, {
            category = "HARM_CATEGORY_HATE_SPEECH",
            threshold = "BLOCK_NONE"
        }, {
            category = "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            threshold = "BLOCK_NONE"
        }, {
            category = "HARM_CATEGORY_DANGEROUS_CONTENT",
            threshold = "BLOCK_NONE"
        }}
    }

    statusLabel.Text = "Sending to Gemini AI..."

    local success, responseWrapper = pcall(function()
        return HttpService:RequestAsync({
            Url = GEMINI_API_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(requestBody)
        })
    end)

    generateButton.Active = true
    generateButton.BackgroundColor3 = originalButtonColor
    generateButton.TextColor3 = THEME.AccentTextColor
    generateButton.Text = originalButtonText

    if not success then
        statusLabel.Text = "Critical Error: RequestAsync failed. " .. tostring(responseWrapper)
        warn(pluginName .. ": pcall for RequestAsync failed:", responseWrapper)
        return nil
    end

    if not responseWrapper or not responseWrapper.Success then
        statusLabel.Text = "API request failed (" .. (responseWrapper and responseWrapper.StatusCode or "N/A") ..
                               "). Check Output."
        warn(pluginName .. ": API Request Failed. Full response:", responseWrapper)
        return nil
    end

    statusLabel.Text = "Decoding response..."

    local responseData
    local decodeSuccess, decodeResult = pcall(function()
        responseData = HttpService:JSONDecode(responseWrapper.Body)
    end)

    if not decodeSuccess then
        statusLabel.Text = "Error: Failed to decode API JSON response."
        warn(pluginName .. ": JSON Decode Error: ", decodeResult, "Original Body:", responseWrapper.Body)
        return nil
    end

    if responseData.candidates and responseData.candidates[1] and responseData.candidates[1].content and
        responseData.candidates[1].content.parts and responseData.candidates[1].content.parts[1] and
        responseData.candidates[1].content.parts[1].text then

        local generatedCode = responseData.candidates[1].content.parts[1].text
        -- Clean the response from markdown code blocks
        generatedCode = generatedCode:gsub("^```lua\n", ""):gsub("\n```$", ""):gsub("`", "")

        statusLabel.Text = "Code extracted. Generating UI..."
        return generatedCode
    else
        local errMessage = "Unexpected API response format."
        if responseData.error then
            errMessage = "API Error: " .. (responseData.error.message or "Unknown")
        end
        statusLabel.Text = errMessage
        warn(pluginName .. ": Gemini API response format issue. Full response data:", responseData)
        return nil
    end
end

-- Function to execute the generated code
local function executeGeneratedCode(codeToExecute)
    if not codeToExecute or #codeToExecute == 0 then
        statusLabel.Text = "No code was generated."
        return
    end

    ChangeHistoryService:SetWaypoint("Before Gemini UI Generation")

    local targetParent = game:GetService("StarterGui")
    local selectedObjects = Selection:Get()
    if #selectedObjects > 0 and (selectedObjects[1]:IsA("ScreenGui") or selectedObjects[1]:IsA("GuiObject")) then
        targetParent = selectedObjects[1]
        statusLabel.Text = "Targeting: " .. targetParent.Name
    else
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "GeminiGeneratedUI"
        screenGui.Parent = game:GetService("StarterGui")
        targetParent = screenGui
        statusLabel.Text = "Created new ScreenGui."
    end

    local tempScript = Instance.new("Script")
    tempScript.Name = "GeminiExecutor_" .. HttpService:GenerateGUID(false)

    local success, err = pcall(function()
        local func, loadErr = loadstring(codeToExecute)
        if func then
            local env = getfenv(func)
            env.script = tempScript -- Set the 'script' global to our temporary script
            setfenv(func, env)

            tempScript.Parent = targetParent -- Parent the script to allow 'script.Parent' to work

            local pcallSuccess, pcallResult = pcall(func)
            if not pcallSuccess then
                error("Error during execution of generated code: " .. tostring(pcallResult))
            end
        else
            error("Error loading generated code: " .. tostring(loadErr))
        end
    end)

    -- Clean up the temporary script regardless of success
    tempScript:Destroy()

    if success then
        statusLabel.Text = "Successfully generated UI in " .. targetParent:GetFullName()
        ChangeHistoryService:SetWaypoint("After Gemini UI Generation")
    else
        statusLabel.Text = "Error executing code. Check Output for details."
        warn(pluginName .. ": Error executing generated code - ", err)
        ChangeHistoryService:TryUndo()
        if targetParent.Name == "GeminiGeneratedUI" and #targetParent:GetChildren() == 0 then
            targetParent:Destroy() -- Clean up empty generated ScreenGui on failure
        end
    end
end

-- Event Handlers
button.Click:Connect(function()
    widget.Enabled = not widget.Enabled
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
    button:SetActive(widget.Enabled)
    if widget.Enabled then
        statusLabel.Text = "Ready."
        promptTextBox:CaptureFocus()
    end
end)

generateButton.MouseButton1Click:Connect(function()
    if not generateButton.Active then
        return
    end

    local prompt = promptTextBox.Text
    if prompt and #prompt > 3 then
        task.spawn(function()
            local generatedCode = generateCodeWithGemini(prompt)
            if generatedCode then
                executeGeneratedCode(generatedCode)
            end
        end)
    else
        statusLabel.Text = "Please enter a more detailed description."
    end
end)

plugin.Unloading:Connect(function()
    if widget then
        widget:Destroy()
    end
    if toolbar then
        toolbar:Destroy()
    end
end)

button:SetActive(widget.Enabled)
print(pluginName .. " loaded. Make sure HTTP Requests are enabled.")
