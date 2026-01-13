/**
 * 钱包跟单核心类
 */
import { ProfitTracker } from './ProfitTracker.js';

export class WalletFollower {
  constructor(sdk, config) {
    this.sdk = sdk;
    this.config = config;
    this.watchingWallets = new Set();
    this.isRunning = false;
    this.copyTradingSubscription = null;
    
    // 初始化盈利统计器
    if (config.profitTracking?.enabled !== false) {
      this.profitTracker = new ProfitTracker({
        autoSaveInterval: config.profitTracking?.autoSaveInterval || 60000,
      });
      
      // 定期显示统计信息
      this.statsDisplayInterval = null;
      if (config.profitTracking?.displayInterval && config.profitTracking.displayInterval > 0) {
        // 延迟设置，确保方法已定义
        setTimeout(() => {
          this.setupStatsDisplay(config.profitTracking.displayInterval);
        }, 1000);
      }
    } else {
      this.profitTracker = null;
      this.statsDisplayInterval = null;
    }
  }

  /**
   * 初始化钱包跟单系统
   */
  async initialize() {
    console.log('🚀 初始化钱包跟单系统...');
    
    try {
      // 获取顶级交易者
      if (this.config.topTradersCount > 0) {
        await this.loadTopTraders();
      }

      // 添加配置的目标钱包
      if (this.config.targetWallets && this.config.targetWallets.length > 0) {
        for (const wallet of this.config.targetWallets) {
          await this.addWallet(wallet);
        }
      }

      console.log(`✅ 初始化完成，正在监听 ${this.watchingWallets.size} 个钱包`);
    } catch (error) {
      console.error('❌ 初始化失败:', error);
      throw error;
    }
  }

  /**
   * 加载顶级交易者
   */
  async loadTopTraders() {
    console.log(`📊 获取前 ${this.config.topTradersCount} 名顶级交易者...`);
    
    try {
      const traders = await this.sdk.wallets.getTopTraders(this.config.topTradersCount);
      
      if (!traders || traders.length === 0) {
        console.warn('⚠️  未找到顶级交易者');
        return;
      }

      // 筛选符合条件的交易者
      let addedCount = 0;
      let filteredCount = 0;
      
      for (const trader of traders) {
        try {
          const profile = await this.sdk.wallets.getWalletProfile(trader.address);
          
          // 应用过滤条件
          const shouldFollow = this.shouldFollowWallet(profile);
          if (shouldFollow) {
            await this.addWallet(trader.address, profile);
            addedCount++;
          } else {
            filteredCount++;
            // 显示被过滤的原因（仅在调试时）
            const reason = this.getFilterReason(profile);
            if (reason) {
              console.log(`⏭️  钱包 ${trader.address.substring(0, 10)}... 被过滤: ${reason}`);
            }
          }
        } catch (error) {
          console.error(`❌ 处理交易者 ${trader.address} 时出错:`, error.message);
          filteredCount++;
        }
      }
      
      console.log(`✅ 成功加载 ${traders.length} 名交易者`);
      console.log(`   通过过滤: ${addedCount} 个`);
      if (filteredCount > 0) {
        console.log(`   被过滤: ${filteredCount} 个（可能因为胜率或评分不达标）`);
      }
    } catch (error) {
      console.error('❌ 加载顶级交易者失败:', error);
    }
  }

  /**
   * 判断是否应该跟单该钱包
   */
  shouldFollowWallet(profile) {
    const filters = this.config.filters || {};
    
    // 如果没有设置过滤条件（undefined, null, 0 或未定义），默认全部通过
    const minWinRate = filters.minWinRate;
    const minSmartScore = filters.minSmartScore;
    
    const hasWinRateFilter = minWinRate !== undefined && minWinRate !== null && minWinRate > 0;
    const hasScoreFilter = minSmartScore !== undefined && minSmartScore !== null && minSmartScore > 0;
    
    // 如果过滤条件都被注释掉或未设置，默认全部通过
    if (!hasWinRateFilter && !hasScoreFilter) {
      return true;  // 没有过滤条件，全部通过
    }
    
    // 检查胜率（如果设置了过滤条件）
    if (hasWinRateFilter) {
      const winRate = profile.winRate || 0;
      if (winRate < minWinRate * 100) {
        return false;
      }
    }
    
    // 检查智能评分（如果设置了过滤条件）
    if (hasScoreFilter) {
      const smartScore = profile.smartScore || 0;
      if (smartScore < minSmartScore) {
        return false;
      }
    }
    
    return true;
  }

  /**
   * 获取过滤原因（用于调试）
   */
  getFilterReason(profile) {
    const filters = this.config.filters || {};
    const reasons = [];
    
    if (filters.minWinRate && profile.winRate < filters.minWinRate * 100) {
      reasons.push(`胜率 ${profile.winRate?.toFixed(1) || 'N/A'}% < ${(filters.minWinRate * 100).toFixed(1)}%`);
    }
    
    if (filters.minSmartScore && profile.smartScore < filters.minSmartScore) {
      reasons.push(`评分 ${profile.smartScore || 'N/A'} < ${filters.minSmartScore}`);
    }
    
    return reasons.length > 0 ? reasons.join(', ') : null;
  }

  /**
   * 添加要监听的钱包
   */
  async addWallet(walletAddress, profile = null) {
    if (this.watchingWallets.has(walletAddress)) {
      console.log(`⏭️  钱包 ${walletAddress} 已在监听列表中`);
      return;
    }

    // 如果没有提供profile，尝试获取钱包资料
    if (!profile) {
      try {
        profile = await this.sdk.wallets.getWalletProfile(walletAddress);
      } catch (error) {
        console.warn(`⚠️  获取钱包 ${walletAddress.substring(0, 10)}... 资料失败:`, error.message);
        console.log('💡 提示: 钱包可能不存在或未在 Polymarket 上注册，将尝试直接添加');
        // 即使获取资料失败，也添加钱包（可能在后续会有交易）
        profile = {
          address: walletAddress,
          smartScore: 0,
          winRate: 0,
          totalPnL: 0
        };
      }
    }

    // 显示钱包信息
    if (profile && profile.smartScore !== undefined) {
      this.displayWalletInfo(walletAddress, profile);
    } else {
      console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
      console.log(`📝 钱包地址: ${walletAddress}`);
      console.log(`   ⚠️  无法获取详细资料（可能未注册或网络问题）`);
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    }
    
    this.watchingWallets.add(walletAddress);
    console.log(`✅ 已添加钱包到监听列表: ${walletAddress.substring(0, 10)}...`);
  }

  /**
   * 显示钱包信息
   */
  displayWalletInfo(address, profile) {
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`📝 钱包信息: ${address}`);
    console.log(`   智能评分: ${profile.smartScore || 'N/A'}/100`);
    console.log(`   胜率: ${profile.winRate || 'N/A'}%`);
    console.log(`   总盈亏: $${profile.totalPnL || 'N/A'}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  /**
   * 开始监听钱包活动
   */
  async startWatching() {
    if (this.isRunning) {
      console.warn('⚠️  监听已在运行中');
      return;
    }

    if (this.watchingWallets.size === 0) {
      console.warn('⚠️  没有要监听的钱包，请先添加钱包');
      return;
    }

    this.isRunning = true;
    console.log(`👀 开始监听 ${this.watchingWallets.size} 个钱包的交易活动...`);
    
    const interval = this.config.followSettings?.watchInterval || 5000;

    // 定期检查钱包活动
    this.watchInterval = setInterval(async () => {
      await this.checkWalletsActivity();
    }, interval);
  }

  /**
   * 停止监听
   */
  stopWatching() {
    if (this.watchInterval) {
      clearInterval(this.watchInterval);
      this.watchInterval = null;
    }
    this.isRunning = false;
    console.log('⏹️  已停止监听');
  }

  /**
   * 停止所有跟单活动
   */
  async stop() {
    // 停止统计显示
    if (this.statsDisplayInterval) {
      clearInterval(this.statsDisplayInterval);
      this.statsDisplayInterval = null;
    }
    
    // 停止自动跟单订阅
    if (this.copyTradingSubscription) {
      const stats = this.copyTradingSubscription.getStats();
      console.log('\n📊 跟单统计:');
      console.log(`   检测交易: ${stats.tradesDetected}`);
      console.log(`   执行交易: ${stats.tradesExecuted}`);
      console.log(`   成功率: ${stats.tradesExecuted > 0 ? ((stats.tradesExecuted / stats.tradesDetected) * 100).toFixed(2) : 0}%`);
      
      this.copyTradingSubscription.stop();
      this.copyTradingSubscription = null;
      console.log('⏹️  已停止自动跟单');
    }
    
    // 停止手动监听
    this.stopWatching();
    
    // 显示最终盈利统计
    if (this.profitTracker && this.config.profitTracking?.enabled) {
      console.log('\n');
      this.profitTracker.displayStats();
      
      // 保存盈利历史
      await this.profitTracker.destroy();
    }
  }
  
  /**
   * 设置定期显示统计信息
   */
  setupStatsDisplay(intervalMinutes = 30) {
    const intervalMs = intervalMinutes * 60 * 1000;
    
    this.statsDisplayInterval = setInterval(() => {
      if (this.profitTracker && this.profitTracker.stats.totalTrades > 0) {
        console.log('\n');
        this.profitTracker.displayStats();
      }
    }, intervalMs);
    
    console.log(`📊 已启用定期统计显示（每 ${intervalMinutes} 分钟）`);
  }

  /**
   * 检查钱包活动
   */
  async checkWalletsActivity() {
    for (const walletAddress of this.watchingWallets) {
      try {
        await this.checkWalletActivity(walletAddress);
      } catch (error) {
        console.error(`❌ 检查钱包 ${walletAddress} 活动失败:`, error.message);
      }
    }
  }

  /**
   * 检查单个钱包的活动
   */
  async checkWalletActivity(walletAddress) {
    // 这里可以根据 poly-sdk 的实际API来实现
    // 示例：监听交易事件
    try {
      // 如果有交易监听功能
      // const transactions = await this.sdk.wallets.getRecentTransactions(walletAddress);
      // for (const tx of transactions) {
      //   await this.handleTransaction(walletAddress, tx);
      // }
      
      // 或者使用事件监听
      // this.sdk.on('transaction', (tx) => {
      //   if (tx.from === walletAddress || tx.to === walletAddress) {
      //     this.handleTransaction(walletAddress, tx);
      //   }
      // });
    } catch (error) {
      console.error(`检查钱包 ${walletAddress} 时出错:`, error);
    }
  }

  /**
   * 处理交易事件
   */
  async handleTransaction(walletAddress, transaction) {
    console.log(`\n🔔 检测到钱包 ${walletAddress} 的新交易:`);
    console.log(`   交易哈希: ${transaction.hash}`);
    console.log(`   类型: ${transaction.type}`);
    console.log(`   金额: ${transaction.amount}`);
    
    // 检测卖出活动
    if (transaction.type === 'sell' || transaction.amount < 0) {
      await this.handleSellActivity(walletAddress, transaction);
    }
    
    // 检测买入活动
    if (transaction.type === 'buy' || transaction.amount > 0) {
      await this.handleBuyActivity(walletAddress, transaction);
    }
  }

  /**
   * 处理买入活动
   */
  async handleBuyActivity(walletAddress, transaction) {
    const settings = this.config.followSettings;
    
    if (!settings.autoFollow) {
      console.log('ℹ️  自动跟单已禁用，仅记录交易');
      return;
    }

    // 计算跟单金额
    const followAmount = transaction.amount * settings.followRatio;
    
    // 检查金额限制
    if (followAmount < settings.minAmount) {
      console.log(`⏭️  跟单金额 ${followAmount} 低于最小值 ${settings.minAmount}，跳过`);
      return;
    }
    
    if (followAmount > settings.maxAmount) {
      console.log(`⏭️  跟单金额 ${followAmount} 超过最大值 ${settings.maxAmount}，使用最大值`);
      followAmount = settings.maxAmount;
    }

    console.log(`💰 准备跟单买入: $${followAmount}`);
    
    // 执行跟单逻辑
    await this.executeCopyTrade({
      wallet: walletAddress,
      action: 'buy',
      originalAmount: transaction.amount,
      followAmount: followAmount,
      token: transaction.token,
      timestamp: transaction.timestamp || Date.now()
    });
  }

  /**
   * 处理卖出活动
   */
  async handleSellActivity(walletAddress, transaction) {
    console.log(`📉 检测到卖出活动: ${walletAddress}`);
    
    // 检测卖出比例
    try {
      // 假设有条件ID和峰值价值
      // const sellResult = await this.sdk.wallets.detectSellActivity(
      //   walletAddress,
      //   conditionId,
      //   timestamp
      // );
      
      // if (sellResult.isSelling) {
      //   console.log(`   卖出比例: ${sellResult.percentageSold}%`);
      //   
      //   if (this.config.followSettings.autoFollow) {
      //     await this.executeCopyTrade({
      //       wallet: walletAddress,
      //       action: 'sell',
      //       percentage: sellResult.percentageSold,
      //       token: transaction.token
      //     });
      //   }
      // }
    } catch (error) {
      console.error('检测卖出活动失败:', error);
    }
  }

  /**
   * 启动自动跟单交易（使用 SmartMoneyService）
   */
  async startAutoCopyTrading() {
    if (!this.sdk.smartMoney) {
      throw new Error('SmartMoneyService 不可用，请确保SDK已正确初始化');
    }

    const settings = this.config.followSettings || {};
    const filters = this.config.filters || {};

    console.log('📋 自动跟单配置:');
    console.log(`   跟单比例: ${(settings.sizeScale || 0.1) * 100}%`);
    console.log(`   最大单笔金额: $${settings.maxSizePerTrade || 10}`);
    console.log(`   最小交易金额: $${settings.minTradeSize || 5}`);
    console.log(`   滑点容忍度: ${(settings.maxSlippage || 0.03) * 100}%`);
    console.log(`   订单类型: ${settings.orderType || 'FOK'}`);
    
    // ⚠️ 重要警告：真实交易模式
    if (settings.dryRun === false) {
      console.log(`\n⚠️⚠️⚠️  ⚠️⚠️⚠️  ⚠️⚠️⚠️  ⚠️⚠️⚠️  ⚠️⚠️⚠️`);
      console.log(`⚠️  警告：真实交易模式已启用！`);
      console.log(`⚠️  程序将执行真实交易，会消耗您的真实资金！`);
      console.log(`⚠️  如果不想执行真实交易，请立即按 Ctrl+C 停止！`);
      console.log(`⚠️⚠️⚠️  ⚠️⚠️⚠️  ⚠️⚠️⚠️  ⚠️⚠️⚠️  ⚠️⚠️⚠️\n`);
      
      // 等待 5 秒，给用户取消的机会
      console.log('⏳ 5 秒后开始执行真实交易（按 Ctrl+C 取消）...');
      for (let i = 5; i > 0; i--) {
        process.stdout.write(`\r   ${i} 秒...`);
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
      console.log('\n✅ 开始执行真实交易模式\n');
    } else {
      console.log(`   测试模式: ✅ 是（不会执行真实交易）\n`);
    }

    // 准备目标钱包列表
    let targetAddresses = [];
    
    // 如果配置了目标钱包，使用它们
    if (this.config.targetWallets && this.config.targetWallets.length > 0) {
      targetAddresses = this.config.targetWallets;
      console.log(`📌 使用配置的目标钱包: ${targetAddresses.length} 个`);
    } else if (this.config.topTradersCount > 0) {
      // 否则从排行榜获取顶级交易者
      console.log(`📊 从排行榜获取前 ${this.config.topTradersCount} 名交易者...`);
      const traders = await this.sdk.wallets.getTopTraders(this.config.topTradersCount);
      
      // 应用过滤条件
      for (const trader of traders) {
        try {
          const profile = await this.sdk.wallets.getWalletProfile(trader.address);
          if (this.shouldFollowWallet(profile)) {
            targetAddresses.push(trader.address);
            this.displayWalletInfo(trader.address, profile);
          }
        } catch (error) {
          console.error(`获取钱包 ${trader.address} 资料失败:`, error.message);
        }
      }
    }

    if (targetAddresses.length === 0) {
      throw new Error('没有找到符合条件的钱包进行跟单');
    }

    // 启动自动跟单
    // 构建配置对象 - 优先使用 targetAddresses，如果没有则使用 topN
    const copyTradingConfig = {
      // 目标选择（优先使用已筛选的地址列表）
      ...(targetAddresses.length > 0 
        ? { targetAddresses } 
        : (this.config.topTradersCount > 0 ? { topN: this.config.topTradersCount } : {})
      ),

      // 订单设置
      sizeScale: settings.sizeScale || 0.1,
      maxSizePerTrade: settings.maxSizePerTrade || 10,
      maxSlippage: settings.maxSlippage || 0.03,
      orderType: settings.orderType || 'FOK',

      // 过滤
      minTradeSize: settings.minTradeSize || 5,
      ...(settings.sideFilter ? { sideFilter: settings.sideFilter } : {}), // 'BUY' 或 'SELL'，不设置则跟单所有

      // 测试模式
      dryRun: settings.dryRun !== false, // 默认开启测试模式

      // 回调
      onTrade: (trade, result) => {
        console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
        console.log(`🔄 跟单交易: ${trade.traderName || trade.address || '未知交易者'}`);
        console.log(`   操作: ${trade.side || 'UNKNOWN'} ${trade.outcome || ''}`);
        console.log(`   价格: $${trade.price || 'N/A'}`);
        console.log(`   数量: ${trade.size || 0} 份额`);
        console.log(`   金额: $${((trade.price || 0) * (trade.size || 0)).toFixed(2)}`);
        
        if (result.success) {
          console.log(`   结果: ✅ 成功`);
          if (result.orderId) {
            console.log(`   订单ID: ${result.orderId}`);
          }
          
          // 记录成功交易到盈利统计
          if (this.profitTracker && this.config.profitTracking?.enabled) {
            try {
              this.profitTracker.recordTrade({
                walletAddress: trade.address || trade.traderAddress || '',
                tokenAddress: trade.marketId || trade.conditionId || '',
                tokenName: trade.traderName || trade.outcome || '未知',
                side: trade.side?.toUpperCase() || 'BUY',
                amount: (trade.price || 0) * (trade.size || 0),
                price: trade.price || 0,
                timestamp: trade.timestamp ? new Date(trade.timestamp) : new Date(),
                conditionId: trade.conditionId,
                marketId: trade.marketId,
                orderId: result.orderId,
                status: 'CLOSED',
              });
            } catch (error) {
              console.warn('⚠️  记录交易到盈利统计失败:', error.message);
            }
          }
        } else {
          console.log(`   结果: ❌ 失败`);
          
          // 显示详细错误信息
          let errorMsg = '';
          let errorDetails = null;
          
          if (result.error) {
            if (typeof result.error === 'string') {
              errorMsg = result.error;
            } else if (result.error?.message) {
              errorMsg = result.error.message;
              errorDetails = result.error;
            } else {
              errorMsg = JSON.stringify(result.error);
              errorDetails = result.error;
            }
          } else if (result.reason) {
            errorMsg = result.reason;
          } else {
            errorMsg = '未知错误（未提供详细错误信息）';
          }
          
          console.log(`   错误信息: ${errorMsg}`);
          
          // 显示错误堆栈（如果有且启用调试）
          if (errorDetails?.stack && process.env.DEBUG === 'true') {
            console.log(`   错误堆栈: ${errorDetails.stack}`);
          }
          
          // 根据错误类型提供解决建议
          const errorLower = errorMsg.toLowerCase();
          const settings = this.config.followSettings || {};
          
          if (errorLower.includes('insufficient') || errorLower.includes('balance') || errorLower.includes('余额')) {
            console.log(`   💡 建议: 账户余额不足`);
            console.log(`      - 检查 Polymarket 账户 USDC 余额`);
            console.log(`      - 确保余额 >= $${settings.maxSizePerTrade || 10} + 手续费`);
            console.log(`      - 或减小 maxSizePerTrade 配置`);
          } else if (errorLower.includes('slippage') || errorLower.includes('price') || errorLower.includes('滑点') || errorLower.includes('价格')) {
            console.log(`   💡 建议: 价格变动过大（滑点问题）`);
            console.log(`      - 当前滑点容忍度: ${(settings.maxSlippage || 0.03) * 100}%`);
            console.log(`      - 建议增加 maxSlippage 到 0.05 (5%)`);
            console.log(`      - 或改用 orderType: 'FAK' 允许部分成交`);
          } else if (errorLower.includes('min') || errorLower.includes('size') || errorLower.includes('minimum') || errorLower.includes('最小')) {
            console.log(`   💡 建议: 交易金额小于最小值`);
            console.log(`      - 当前最小交易金额: $${settings.minTradeSize || 1}`);
            console.log(`      - Polymarket 最小订单是 $1`);
            console.log(`      - 检查跟单比例 sizeScale 是否过小`);
          } else if (errorLower.includes('network') || errorLower.includes('timeout') || errorLower.includes('连接') || errorLower.includes('网络')) {
            console.log(`   💡 建议: 网络连接问题`);
            console.log(`      - 检查服务器网络连接`);
            console.log(`      - 配置代理（如果在中国大陆）`);
            console.log(`      - 检查防火墙设置`);
          } else if (errorLower.includes('fok') || errorLower.includes('fill') || errorLower.includes('全部成交')) {
            console.log(`   💡 建议: FOK 订单无法全部成交`);
            console.log(`      - 当前订单类型: ${settings.orderType || 'FOK'}`);
            console.log(`      - 建议改用 orderType: 'FAK' 允许部分成交`);
            console.log(`      - 或增加 maxSlippage 容忍度`);
          } else if (errorLower.includes('market') || errorLower.includes('condition') || errorLower.includes('not found') || errorLower.includes('不存在')) {
            console.log(`   💡 建议: 市场或条件不存在`);
            console.log(`      - 市场可能已关闭或条件已过期`);
            console.log(`      - 这是正常的，程序会自动跳过`);
          } else if (errorLower.includes('rate limit') || errorLower.includes('too many') || errorLower.includes('限流')) {
            console.log(`   💡 建议: API 限流`);
            console.log(`      - 请求过于频繁`);
            console.log(`      - 增加 watchInterval 间隔`);
          } else if (errorLower.includes('dry') || errorLower.includes('test') || errorLower.includes('测试')) {
            console.log(`   💡 提示: 测试模式下的失败是正常的`);
            console.log(`      - 当前为测试模式（dryRun: true）`);
            console.log(`      - 测试模式不会执行真实交易`);
          } else {
            console.log(`   💡 通用建议:`);
            console.log(`      - 运行诊断工具: node 诊断跟单失败.js`);
            console.log(`      - 检查配置: orderType, maxSlippage, maxSizePerTrade`);
            console.log(`      - 查看完整错误日志`);
            console.log(`      - 设置 DEBUG=true 查看详细堆栈`);
          }
          
          // 记录失败交易（用于统计分析）
          if (this.profitTracker && this.config.profitTracking?.enabled) {
            try {
              // 提取失败原因分类
              let errorReason = null;
              const errorLower = errorMsg.toLowerCase();
              
              if (errorLower.includes('insufficient') || errorLower.includes('balance') || errorLower.includes('余额')) {
                errorReason = '余额不足';
              } else if (errorLower.includes('slippage') || errorLower.includes('滑点') || errorLower.includes('价格') || errorLower.includes('price moved')) {
                errorReason = '滑点过大';
              } else if (errorLower.includes('min') || errorLower.includes('size') || errorLower.includes('minimum') || errorLower.includes('最小')) {
                errorReason = '金额过小';
              } else if (errorLower.includes('network') || errorLower.includes('timeout') || errorLower.includes('连接') || errorLower.includes('网络')) {
                errorReason = '网络问题';
              } else if (errorLower.includes('fok') || errorLower.includes('fill') || errorLower.includes('全部成交') || errorLower.includes('cannot fill')) {
                errorReason = '无法全部成交';
              } else if (errorLower.includes('market') || errorLower.includes('condition') || errorLower.includes('not found') || errorLower.includes('不存在')) {
                errorReason = '市场不存在';
              } else if (errorLower.includes('rate limit') || errorLower.includes('too many') || errorLower.includes('限流')) {
                errorReason = 'API限流';
              } else if (errorLower.includes('approve') || errorLower.includes('授权') || errorLower.includes('allowance')) {
                errorReason = '未授权';
              } else if (errorLower.includes('dry') || errorLower.includes('test') || errorLower.includes('测试')) {
                errorReason = '测试模式';
              }
              
              this.profitTracker.recordTrade({
                walletAddress: trade.address || trade.traderAddress || '',
                tokenAddress: trade.marketId || trade.conditionId || '',
                tokenName: trade.traderName || trade.outcome || '未知',
                side: trade.side?.toUpperCase() || 'BUY',
                amount: (trade.price || 0) * (trade.size || 0),
                price: trade.price || 0,
                timestamp: trade.timestamp ? new Date(trade.timestamp) : new Date(),
                conditionId: trade.conditionId,
                marketId: trade.marketId,
                status: 'FAILED',
                error: errorMsg,
                errorReason: errorReason || '其他错误',
              });
            } catch (error) {
              console.warn('⚠️  记录失败交易到盈利统计失败:', error.message);
            }
          }
        }
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      },
      onError: (error) => {
        console.error('❌ 跟单错误:', error);
      },
    };

    this.copyTradingSubscription = await this.sdk.smartMoney.startAutoCopyTrading(copyTradingConfig);

    const stats = this.copyTradingSubscription.getStats();
    console.log(`\n✅ 自动跟单已启动`);
    console.log(`   正在跟踪: ${targetAddresses.length} 个钱包`);
    console.log(`   已检测交易: ${stats.tradesDetected}`);
    console.log(`   已执行交易: ${stats.tradesExecuted}`);
    
    // 如果有盈利统计配置，显示初始状态
    if (this.config.profitTracking?.enabled) {
      console.log(`   📊 盈利统计: 已启用`);
      if (this.config.profitTracking?.displayInterval > 0) {
        console.log(`   统计显示: 每 ${this.config.profitTracking.displayInterval} 分钟`);
      }
    }
    console.log('');
    
    // 设置交易回调（如果 SDK 支持）
    if (this.copyTradingSubscription.onTrade) {
      this.copyTradingSubscription.onTrade((trade) => {
        // 记录交易到盈利统计器
        try {
          this.profitTracker.recordTrade({
            walletAddress: trade.walletAddress || trade.wallet,
            tokenAddress: trade.tokenAddress || trade.token,
            tokenName: trade.tokenName || trade.token,
            side: trade.side || trade.action,
            amount: trade.amount || trade.followAmount,
            price: trade.price || 0,
            timestamp: trade.timestamp ? new Date(trade.timestamp) : new Date(),
            conditionId: trade.conditionId,
            marketId: trade.marketId,
            orderId: trade.orderId,
          });
        } catch (error) {
          console.warn('⚠️  记录交易失败:', error.message);
        }
      });
    }
  }

  /**
   * 执行跟单交易（手动模式）
   */
  async executeCopyTrade(tradeInfo) {
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🔄 执行跟单交易:');
    console.log(`   来源钱包: ${tradeInfo.wallet}`);
    console.log(`   操作: ${tradeInfo.action}`);
    console.log(`   代币: ${tradeInfo.token || 'N/A'}`);
    console.log(`   原始金额: $${tradeInfo.originalAmount || 'N/A'}`);
    console.log(`   跟单金额: $${tradeInfo.followAmount || 'N/A'}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    // 记录交易到盈利统计器
    try {
      const tradeRecord = this.profitTracker.recordTrade({
        walletAddress: tradeInfo.wallet,
        tokenAddress: tradeInfo.token,
        tokenName: tradeInfo.tokenName || tradeInfo.token,
        side: tradeInfo.action?.toUpperCase() === 'BUY' ? 'BUY' : 'SELL',
        amount: tradeInfo.followAmount || tradeInfo.originalAmount || 0,
        price: tradeInfo.price || 0,
        timestamp: tradeInfo.timestamp ? new Date(tradeInfo.timestamp) : new Date(),
        conditionId: tradeInfo.conditionId,
        marketId: tradeInfo.marketId,
        orderId: tradeInfo.orderId,
      });
      
      // 如果有盈利，显示
      if (tradeRecord.profit !== null) {
        console.log(`💰 交易盈利: $${tradeRecord.profit.toFixed(2)} (${tradeRecord.profitPercent}%)`);
      }
    } catch (error) {
      console.warn('⚠️  记录交易到盈利统计器失败:', error.message);
    }
    
    // 注意：这里只是示例输出，实际执行需要使用 TradingService
    // 如果启用了自动跟单，应该使用 startAutoCopyTrading 方法
    console.log('⚠️  注意：手动跟单需要实现交易逻辑');
  }
  
  /**
   * 显示盈利统计
   */
  displayProfitStats() {
    this.profitTracker.displayStats();
  }
  
  /**
   * 获取盈利统计摘要
   */
  getProfitSummary() {
    return this.profitTracker.getSummary();
  }

  /**
   * 跟踪群体卖出比例
   */
  async trackGroupSellRatio(walletAddresses, conditionId, peakValue, sinceTimestamp) {
    try {
      const result = await this.sdk.wallets.trackGroupSellRatio(
        walletAddresses,
        conditionId,
        peakValue,
        sinceTimestamp
      );
      
      console.log(`📊 群体卖出统计:`);
      console.log(`   钱包数量: ${walletAddresses.length}`);
      console.log(`   平均卖出比例: ${result.averageRatio || 'N/A'}%`);
      
      return result;
    } catch (error) {
      console.error('跟踪群体卖出比例失败:', error);
      throw error;
    }
  }

  /**
   * 获取钱包统计信息
   */
  async getWalletStats(walletAddress) {
    try {
      const profile = await this.sdk.wallets.getWalletProfile(walletAddress);
      return {
        address: walletAddress,
        smartScore: profile.smartScore,
        winRate: profile.winRate,
        totalPnL: profile.totalPnL,
        // 根据实际API返回添加更多字段
      };
    } catch (error) {
      console.error(`获取钱包 ${walletAddress} 统计信息失败:`, error);
      return null;
    }
  }
}
