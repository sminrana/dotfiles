local M = {}
local utils = require("user.utils")

function M.do_upload(finalFile)
  local filename = vim.fn.fnamemodify(finalFile, ":t")
  filename = utils.random_filename_with_ext(filename)
  local bucket = "smindev"
  local s3_path = "s3://" .. bucket .. "/static/" .. filename

  vim.notify("Uploading to S3: " .. filename, vim.log.levels.INFO)

  vim.system({ "aws", "s3", "cp", finalFile, s3_path, "--acl", "public-read" }, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code == 0 then
        local url = "https://smin.dev/scr/" .. filename
        vim.fn.setreg("+", url)
        vim.notify("Public URL copied: " .. url, vim.log.levels.INFO)
      else
        vim.notify("Failed to upload: " .. (obj.stderr or ""), vim.log.levels.ERROR)
      end
    end)
  end)
end

function M.upload_to_s3(file)
  if file:match("%.mov$") then
    local mp4_file = file:gsub("%.mov$", ".mp4")
    if vim.fn.executable("ffmpeg") ~= 1 then
      vim.notify("ffmpeg is not installed.", vim.log.levels.ERROR)
      return
    end
    vim.notify("Converting .mov to .mp4...", vim.log.levels.INFO)
    vim.system(
      { "ffmpeg", "-y", "-i", file, "-vcodec", "libx264", "-acodec", "aac", mp4_file },
      { text = true },
      function(obj)
        vim.schedule(function()
          if obj.code == 0 then
            M.do_upload(mp4_file)
          else
            vim.notify("ffmpeg failed: " .. (obj.stderr or ""), vim.log.levels.ERROR)
          end
        end)
      end
    )
    return
  end
  M.do_upload(file)
end

function M.send_file_to_s3()
  vim.ui.input({ prompt = "Enter file path to upload: ", completion = "file" }, function(file)
    if not file or file == "" or vim.fn.filereadable(file) == 0 then
      return
    end
    vim.ui.input({ prompt = "Upload " .. file .. "? (y/n) " }, function(confirm)
      if confirm and confirm:lower() == "y" then
        M.upload_to_s3(file)
      end
    end)
  end)
end

function M.select_file_to_move_to_s3()
  require("fzf-lua").files({
    cwd = "~/Downloads/screenshots/",
    prompt = "S3 Upload> ",
    actions = {
      ["default"] = function(selected)
        if selected then
          M.upload_to_s3(vim.fn.expand("~/Downloads/screenshots/") .. selected[1])
        end
      end,
    },
  })
end

function M.copy_to_s3()
  local file = vim.fn.expand("%:p")
  M.upload_to_s3(file)
end

return M
