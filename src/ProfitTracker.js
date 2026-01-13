/**
 * 盈利统计跟踪器
 */
export class ProfitTracker {
  constructor(config = {}) {
    this.config = config;
    this.stats = {
      // 总体统计
      totalTrades: 0,
      winningTrades: 0,
      losingTrades: 0,
      breakevenTrades: 0,
      failedTrades: 0,  // 失败交易数
      
      // 金额统计
      totalProfit: 0,  // 总盈利（美元）
      totalLoss: 0,    // 总亏损（美元）
      netProfit: 0,    // 净利润（美元）
      
      // 单个交易记录
      trades: [],      // 所有交易记录
      
      // 按钱包统计
      walletStats: new Map(),  // Map<walletAddress, stats>
      
      // 按代币统计
      tokenStats: new Map(),   // Map<tokenAddress, stats>
      
      // 时间统计
      dailyStats: new Map(),   // Map<date, stats>
      
      // 失败原因统计
      failureReasons: new Map(),  // Map<reason, count>
      
      // 开始时间
      startTime: new Date(),
    };
    
    // 自动保存间隔（毫秒）
    this.autoSaveInterval = config.autoSaveInterval || 60000; // 默认 1 分钟
    this.autoSaveTimer = null;
    
    // 加载历史数据（如果存在）
    this.loadHistory();
  }

  /**
   * 记录一笔交易
   */
  recordTrade(trade) {
    const {
      walletAddress,
      tokenAddress,
      tokenName,
      side,        // 'BUY' 或 'SELL'
      amount,      // 交易金额（美元）
      price,       // 交易价格
      timestamp = new Date(),
      conditionId,
      marketId,
      orderId,
      status = 'OPEN',  // 'OPEN', 'CLOSED', 'FAILED', 'CANCELLED'
      error,            // 错误信息（如果失败）
      errorReason,      // 失败原因分类（如果失败）
      ...other
    } = trade;
    
    // 如果交易失败，只记录统计信息，不计算盈利
    if (status === 'FAILED') {
      const errorMsg = error || '未知错误';
      const reason = errorReason || this.categorizeError(errorMsg);
      
      const tradeRecord = {
        id: `${timestamp.getTime()}-${Math.random().toString(36).substr(2, 9)}`,
        walletAddress,
        tokenAddress,
        tokenName,
        side,
        amount,
        price,
        timestamp,
        conditionId,
        marketId,
        orderId,
        status: 'FAILED',
        error: errorMsg,
        errorReason: reason,
        profit: 0,
        profitPercent: 0,
        ...other
      };
      
      // 添加到交易记录（用于分析失败原因）
      this.stats.trades.push(tradeRecord);
      
      // 更新失败统计
      this.stats.failedTrades++;
      this.updateFailureReasonStats(reason);
      
      // 失败交易不计入总交易数（用于胜率计算），但会记录
      
      return tradeRecord;
    }

    // 创建交易记录
    const tradeRecord = {
      id: `${timestamp.getTime()}-${Math.random().toString(36).substr(2, 9)}`,
      walletAddress,
      tokenAddress,
      tokenName,
      side,
      amount,
      price,
      timestamp,
      conditionId,
      marketId,
      orderId,
      profit: null,      // 盈利（将在平仓时计算）
      profitPercent: null,
      status: 'OPEN',    // 'OPEN', 'CLOSED', 'CANCELLED'
      ...other
    };

    // 如果是卖出，计算盈利
    if (side === 'SELL') {
      // 找到对应的买入交易
      const buyTrade = this.findMatchingBuyTrade(walletAddress, tokenAddress, conditionId);
      if (buyTrade) {
        const profit = this.calculateProfit(buyTrade, tradeRecord);
        tradeRecord.profit = profit;
        tradeRecord.profitPercent = buyTrade.price > 0 
          ? ((profit / (buyTrade.amount * buyTrade.price)) * 100).toFixed(2)
          : 0;
        tradeRecord.status = 'CLOSED';
        buyTrade.status = 'CLOSED';
        
        // 更新统计
        this.updateStatsFromTrade(profit);
      }
    }

    // 添加到交易记录
    this.stats.trades.push(tradeRecord);
    this.stats.totalTrades++;

    // 更新钱包统计
    this.updateWalletStats(walletAddress, tradeRecord);

    // 更新代币统计
    if (tokenAddress) {
      this.updateTokenStats(tokenAddress, tradeRecord);
    }

    // 更新每日统计
    this.updateDailyStats(timestamp, tradeRecord);

    // 自动保存
    this.scheduleAutoSave();

    return tradeRecord;
  }

  /**
   * 找到匹配的买入交易
   */
  findMatchingBuyTrade(walletAddress, tokenAddress, conditionId) {
    // 按照 FIFO（先进先出）原则查找
    return this.stats.trades
      .filter(t => 
        t.walletAddress === walletAddress &&
        t.tokenAddress === tokenAddress &&
        (conditionId ? t.conditionId === conditionId : true) &&
        t.side === 'BUY' &&
        t.status === 'OPEN'
      )
      .sort((a, b) => a.timestamp - b.timestamp)[0];
  }

  /**
   * 计算盈利
   */
  calculateProfit(buyTrade, sellTrade) {
    // 简单计算：卖出金额 - 买入金额
    // 实际应该考虑数量、价格等因素
    const buyAmount = buyTrade.amount || 0;
    const buyPrice = buyTrade.price || 0;
    const sellAmount = sellTrade.amount || 0;
    const sellPrice = sellTrade.price || 0;

    // 如果金额和价格都有，计算实际盈利
    if (buyPrice > 0 && sellPrice > 0) {
      const buyCost = buyAmount * buyPrice;
      const sellRevenue = sellAmount * sellPrice;
      return sellRevenue - buyCost;
    }

    // 否则简单计算金额差
    return sellAmount - buyAmount;
  }

  /**
   * 更新统计数据
   */
  updateStatsFromTrade(profit) {
    this.stats.netProfit += profit;

    if (profit > 0) {
      this.stats.winningTrades++;
      this.stats.totalProfit += profit;
    } else if (profit < 0) {
      this.stats.losingTrades++;
      this.stats.totalLoss += Math.abs(profit);
    } else {
      this.stats.breakevenTrades++;
    }
  }

  /**
   * 更新钱包统计
   */
  updateWalletStats(walletAddress, tradeRecord) {
    if (!this.stats.walletStats.has(walletAddress)) {
      this.stats.walletStats.set(walletAddress, {
        totalTrades: 0,
        winningTrades: 0,
        losingTrades: 0,
        totalProfit: 0,
        totalLoss: 0,
        netProfit: 0,
      });
    }

    const walletStat = this.stats.walletStats.get(walletAddress);
    walletStat.totalTrades++;

    if (tradeRecord.profit !== null) {
      walletStat.netProfit += tradeRecord.profit;
      if (tradeRecord.profit > 0) {
        walletStat.winningTrades++;
        walletStat.totalProfit += tradeRecord.profit;
      } else if (tradeRecord.profit < 0) {
        walletStat.losingTrades++;
        walletStat.totalLoss += Math.abs(tradeRecord.profit);
      }
    }
  }

  /**
   * 更新代币统计
   */
  updateTokenStats(tokenAddress, tradeRecord) {
    if (!this.stats.tokenStats.has(tokenAddress)) {
      this.stats.tokenStats.set(tokenAddress, {
        tokenName: tradeRecord.tokenName || tokenAddress,
        totalTrades: 0,
        totalVolume: 0,
        totalProfit: 0,
        avgProfit: 0,
      });
    }

    const tokenStat = this.stats.tokenStats.get(tokenAddress);
    tokenStat.totalTrades++;
    tokenStat.totalVolume += tradeRecord.amount || 0;

    if (tradeRecord.profit !== null) {
      tokenStat.totalProfit += tradeRecord.profit;
      tokenStat.avgProfit = tokenStat.totalProfit / tokenStat.winningTrades;
    }
  }

  /**
   * 更新每日统计
   */
  updateDailyStats(timestamp, tradeRecord) {
    const date = timestamp.toISOString().split('T')[0]; // YYYY-MM-DD

    if (!this.stats.dailyStats.has(date)) {
      this.stats.dailyStats.set(date, {
        date,
        totalTrades: 0,
        totalProfit: 0,
        totalLoss: 0,
        netProfit: 0,
      });
    }

    const dailyStat = this.stats.dailyStats.get(date);
    dailyStat.totalTrades++;

    if (tradeRecord.profit !== null) {
      dailyStat.netProfit += tradeRecord.profit;
      if (tradeRecord.profit > 0) {
        dailyStat.totalProfit += tradeRecord.profit;
      } else {
        dailyStat.totalLoss += Math.abs(tradeRecord.profit);
      }
    }
  }

  /**
   * 获取统计摘要
   */
  getSummary() {
    const winRate = this.stats.totalTrades > 0
      ? ((this.stats.winningTrades / (this.stats.winningTrades + this.stats.losingTrades)) * 100).toFixed(2)
      : 0;

    const avgProfit = this.stats.winningTrades > 0
      ? (this.stats.totalProfit / this.stats.winningTrades).toFixed(2)
      : 0;

    const avgLoss = this.stats.losingTrades > 0
      ? (this.stats.totalLoss / this.stats.losingTrades).toFixed(2)
      : 0;

    const profitFactor = this.stats.totalLoss > 0
      ? (this.stats.totalProfit / this.stats.totalLoss).toFixed(2)
      : this.stats.totalProfit > 0 ? '∞' : '0';

    const runtime = Math.floor((new Date() - this.stats.startTime) / 1000 / 60); // 分钟

    return {
      ...this.stats,
      summary: {
        winRate: parseFloat(winRate),
        avgProfit: parseFloat(avgProfit),
        avgLoss: parseFloat(avgLoss),
        profitFactor: profitFactor,
        runtimeMinutes: runtime,
        tradesPerHour: runtime > 0 ? ((this.stats.totalTrades / runtime) * 60).toFixed(2) : 0,
      }
    };
  }

  /**
   * 显示统计信息
   */
  displayStats() {
    const summary = this.getSummary();
    const s = summary;

    console.log('\n╔════════════════════════════════════════════╗');
    console.log('║           盈利统计报告                    ║');
    console.log('╚════════════════════════════════════════════╝\n');

    // 总体统计
    console.log('📊 总体统计:');
    console.log(`   总交易数: ${s.totalTrades}`);
    console.log(`   盈利交易: ${s.winningTrades} (${s.summary.winRate}%)`);
    console.log(`   亏损交易: ${s.losingTrades}`);
    console.log(`   持平交易: ${s.breakevenTrades}`);
    console.log('');

    // 金额统计
    console.log('💰 金额统计:');
    console.log(`   总盈利: $${s.totalProfit.toFixed(2)}`);
    console.log(`   总亏损: $${s.totalLoss.toFixed(2)}`);
    console.log(`   净利润: $${s.netProfit.toFixed(2)} ${s.netProfit >= 0 ? '✅' : '❌'}`);
    console.log(`   平均盈利: $${s.summary.avgProfit}`);
    console.log(`   平均亏损: $${s.summary.avgLoss}`);
    console.log(`   盈亏比: ${s.summary.profitFactor}`);
    console.log('');

    // 效率统计
    console.log('⚡ 效率统计:');
    console.log(`   运行时间: ${s.summary.runtimeMinutes} 分钟`);
    console.log(`   交易频率: ${s.summary.tradesPerHour} 笔/小时`);
    console.log('');

    // 按钱包统计（Top 5）
    if (s.walletStats.size > 0) {
      console.log('👛 按钱包统计 (Top 5):');
      const walletArray = Array.from(s.walletStats.entries())
        .map(([addr, stats]) => ({ address: addr, ...stats }))
        .sort((a, b) => b.netProfit - a.netProfit)
        .slice(0, 5);

      walletArray.forEach((stat, index) => {
        console.log(`   ${index + 1}. ${stat.address.substring(0, 10)}...`);
        console.log(`      交易: ${stat.totalTrades} | 盈利: $${stat.netProfit.toFixed(2)}`);
      });
      console.log('');
    }

    // 按代币统计（Top 5）
    if (s.tokenStats.size > 0) {
      console.log('🪙 按代币统计 (Top 5):');
      const tokenArray = Array.from(s.tokenStats.entries())
        .map(([addr, stats]) => ({ address: addr, ...stats }))
        .sort((a, b) => b.totalProfit - a.totalProfit)
        .slice(0, 5);

      tokenArray.forEach((stat, index) => {
        console.log(`   ${index + 1}. ${stat.tokenName || stat.address.substring(0, 10)}...`);
        console.log(`      交易: ${stat.totalTrades} | 盈利: $${stat.totalProfit.toFixed(2)}`);
      });
      console.log('');
    }

    // 每日统计（最近 7 天）
    if (s.dailyStats.size > 0) {
      console.log('📅 每日统计 (最近 7 天):');
      const dailyArray = Array.from(s.dailyStats.entries())
        .map(([date, stats]) => ({ date, ...stats }))
        .sort((a, b) => b.date.localeCompare(a.date))
        .slice(0, 7);

      dailyArray.forEach(stat => {
        console.log(`   ${stat.date}: ${stat.totalTrades} 笔 | 净利润: $${stat.netProfit.toFixed(2)}`);
      });
      console.log('');
    }

    // 失败原因统计
    if (s.failureReasons && s.failureReasons.size > 0) {
      console.log('❌ 失败原因统计:');
      const failureArray = Array.from(s.failureReasons.entries())
        .map(([reason, count]) => ({ reason, count }))
        .sort((a, b) => b.count - a.count);

      failureArray.forEach(stat => {
        console.log(`   ${stat.reason}: ${stat.count} 次`);
      });
      console.log('');
    }

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  /**
   * 保存历史数据
   */
  async saveHistory() {
    try {
      const fs = await import('fs/promises');
      const path = await import('path');
      
      const dataDir = path.join(process.cwd(), 'data');
      const filePath = path.join(dataDir, 'profit-history.json');

      // 确保目录存在
      await fs.mkdir(dataDir, { recursive: true });

      // 准备保存的数据（将 Map 转换为普通对象）
      const dataToSave = {
        ...this.stats,
        walletStats: Object.fromEntries(this.stats.walletStats),
        tokenStats: Object.fromEntries(this.stats.tokenStats),
        dailyStats: Object.fromEntries(this.stats.dailyStats),
        failureReasons: Object.fromEntries(this.stats.failureReasons),
        lastSaved: new Date().toISOString(),
      };

      await fs.writeFile(filePath, JSON.stringify(dataToSave, null, 2), 'utf-8');
      return true;
    } catch (error) {
      console.error('保存盈利历史失败:', error.message);
      return false;
    }
  }

  /**
   * 加载历史数据
   */
  async loadHistory() {
    try {
      const fs = (await import('fs/promises')).default || await import('fs/promises');
      const path = (await import('path')).default || await import('path');
      
      const dataDir = path.join(process.cwd(), 'data');
      const filePath = path.join(dataDir, 'profit-history.json');

      const data = await fs.readFile(filePath, 'utf-8');
      const loaded = JSON.parse(data);

      // 恢复 Map 对象
      this.stats = {
        ...loaded,
        walletStats: new Map(Object.entries(loaded.walletStats || {})),
        tokenStats: new Map(Object.entries(loaded.tokenStats || {})),
        dailyStats: new Map(Object.entries(loaded.dailyStats || {})),
        failureReasons: new Map(Object.entries(loaded.failureReasons || {})),
        startTime: loaded.startTime ? new Date(loaded.startTime) : new Date(),
        failedTrades: loaded.failedTrades || 0,
      };

      console.log('✅ 已加载历史盈利数据');
      return true;
    } catch (error) {
      // 文件不存在是正常的（首次运行）
      if (error.code !== 'ENOENT') {
        console.warn('加载盈利历史失败:', error.message);
      }
      return false;
    }
  }

  /**
   * 安排自动保存
   */
  scheduleAutoSave() {
    if (this.autoSaveTimer) {
      clearTimeout(this.autoSaveTimer);
    }

    this.autoSaveTimer = setTimeout(() => {
      this.saveHistory();
    }, this.autoSaveInterval);
  }

  /**
   * 清理资源
   */
  async destroy() {
    if (this.autoSaveTimer) {
      clearTimeout(this.autoSaveTimer);
    }
    await this.saveHistory();
  }
}
