# 🔧 Server Quick Fix Guide

## Issues Found

You encountered two problems:

1. **Version Error**: `npm error notarget No matching version found for @catalyst-team/poly-sdk@^0.4.3`
   - Actual available version is `0.4.0`, not `0.4.3`

2. **Command Error**: `Command 'pnpm' not found`
   - Should use `npm` instead of `pnpm`

## Quick Fix (Copy & Paste)

Run these commands on your server:

```bash
# 1. Navigate to project directory
cd /opt/polybot

# 2. Fix package.json version
sed -i 's/"@catalyst-team\/poly-sdk": "\^0.4.3"/"@catalyst-team\/poly-sdk": "0.4.0"/g' package.json

# 3. Clear npm cache
npm cache clean --force

# 4. Remove old dependencies
rm -rf node_modules package-lock.json

# 5. Use Chinese mirror for faster download
npm config set registry https://registry.npmmirror.com

# 6. Install dependencies
npm install

# 7. Verify installation
npm list @catalyst-team/poly-sdk

# 8. Start (use npm, NOT pnpm)
npm start
```

## Important Notes

### Use npm, NOT pnpm

**Correct commands:**
```bash
npm install   # ✅ Correct
npm start     # ✅ Correct
```

**Wrong commands:**
```bash
pnpm install  # ❌ Wrong - Command 'pnpm' not found
pnpm start    # ❌ Wrong
```

## One-Line Fix

```bash
cd /opt/polybot && sed -i 's/0.4.3/0.4.0/g' package.json && npm cache clean --force && rm -rf node_modules package-lock.json && npm config set registry https://registry.npmmirror.com && npm install && npm start
```

## Verification

After fixing, verify:

```bash
# Check version in package.json
cat package.json | grep poly-sdk
# Should show: "@catalyst-team/poly-sdk": "0.4.0"

# Check installed version
npm list @catalyst-team/poly-sdk
# Should show: @catalyst-team/poly-sdk@0.4.0

# Test run
npm start
```

## If Still Having Issues

### Network Problems

```bash
# Try official registry
npm config set registry https://registry.npmjs.org
npm install

# Or use mirror
npm config set registry https://registry.npmmirror.com
npm install
```

### Permission Problems

```bash
# Use sudo if needed
sudo npm install

# Or fix npm permissions
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH
npm install
```

---

**Remember**: Use `npm`, not `pnpm`! ✅
