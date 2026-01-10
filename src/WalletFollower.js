/**
 * 钱包跟单核心类
 */
export class WalletFollower {
  constructor(sdk, config) {
    this.sdk = sdk;
    this.config = config;
    this.watchingWallets = new Set();
    this.isRunning = false;
    this.copyTradingSubscription = null;
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
      for (const trader of traders) {
        const profile = await this.sdk.wallets.getWalletProfile(trader.address);
        
        // 应用过滤条件
        if (this.shouldFollowWallet(profile)) {
          await this.addWallet(trader.address, profile);
        }
      }
      
      console.log(`✅ 成功加载 ${traders.length} 名交易者`);
    } catch (error) {
      console.error('❌ 加载顶级交易者失败:', error);
    }
  }

  /**
   * 判断是否应该跟单该钱包
   */
  shouldFollowWallet(profile) {
    const filters = this.config.filters || {};
    
    // 检查胜率
    if (filters.minWinRate && profile.winRate < filters.minWinRate * 100) {
      return false;
    }
    
    // 检查智能评分
    if (filters.minSmartScore && profile.smartScore < filters.minSmartScore) {
      return false;
    }
    
    return true;
  }

  /**
   * 添加要监听的钱包
   */
  async addWallet(walletAddress, profile = null) {
    if (this.watchingWallets.has(walletAddress)) {
      console.log(`⏭️  钱包 ${walletAddress} 已在监听列表中`);
      return;
    }

    // 如果没有提供profile，获取钱包资料
    if (!profile) {
      try {
        profile = await this.sdk.wallets.getWalletProfile(walletAddress);
      } catch (error) {
        console.error(`❌ 获取钱包 ${walletAddress} 资料失败:`, error);
        return;
      }
    }

    // 显示钱包信息
    this.displayWalletInfo(walletAddress, profile);
    
    this.watchingWallets.add(walletAddress);
    console.log(`✅ 已添加钱包到监听列表: ${walletAddress}`);
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
    console.log(`   测试模式: ${settings.dryRun !== false ? '是' : '否'}\n`);

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
        console.log(`\n🔄 跟单交易: ${trade.traderName || trade.address}`);
        console.log(`   操作: ${trade.side} ${trade.outcome}`);
        console.log(`   价格: $${trade.price}`);
        console.log(`   数量: ${trade.size} 份额`);
        console.log(`   结果: ${result.success ? '✅ 成功' : '❌ 失败'}`);
        if (result.success && result.orderId) {
          console.log(`   订单ID: ${result.orderId}`);
        }
        if (result.error) {
          console.log(`   错误: ${result.error}`);
        }
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
    console.log(`   已执行交易: ${stats.tradesExecuted}\n`);
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
    
    // 注意：这里只是示例输出，实际执行需要使用 TradingService
    // 如果启用了自动跟单，应该使用 startAutoCopyTrading 方法
    console.log('⚠️  注意：手动跟单需要实现交易逻辑');
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
