/**
 * PolyBot - 钱包跟单机器人主入口
 */
import { PolymarketSDK } from '@catalyst-team/poly-sdk';
import config from './config.js';
import { WalletFollower } from './src/WalletFollower.js';

async function main() {
  console.log('╔════════════════════════════════════════════╗');
  console.log('║         PolyBot - 钱包跟单机器人          ║');
  console.log('╚════════════════════════════════════════════╝\n');

  let sdk = null;
  let follower = null;

  try {
    // 检查配置文件
    if (!config) {
      console.error('❌ 错误: 未找到配置文件');
      console.log('💡 提示: 请复制 config.example.js 为 config.js 并填入配置');
      process.exit(1);
    }

    // 初始化 poly-sdk
    console.log('🔧 初始化 poly-sdk...');
    
    // 检查私钥（支持环境变量和配置文件）
    // 优先使用环境变量，其次使用配置文件
    const privateKeyFromEnv = process.env.POLYMARKET_PRIVATE_KEY?.trim() || '';
    const privateKeyFromConfig = (config.sdk?.privateKey || '').trim();
    const privateKey = privateKeyFromEnv || privateKeyFromConfig;
    
    console.log(`🔑 私钥检查: ${privateKey ? `✅ 已找到 (${privateKey.length} 字符)` : '❌ 未找到'}`);
    
    if (privateKey) {
      try {
        // 使用静态工厂方法（推荐）- 一行代码完成初始化
        console.log('⏳ 正在初始化交易模式...');
        sdk = await PolymarketSDK.create({
          privateKey: privateKey,
          chainId: config.sdk.chainId || 137, // Polygon 主网
        });
        console.log('✅ poly-sdk 初始化成功（交易模式）\n');
      } catch (error) {
        console.error('⚠️  交易模式初始化失败:', error.message);
        console.log('💡 可能的原因:');
        console.log('   1. 钱包未在 Polymarket 注册');
        console.log('   2. 网络连接问题');
        console.log('   3. 私钥对应的钱包地址错误');
        console.log('\n🔄 回退到只读模式...\n');
        // 回退到只读模式
        sdk = new PolymarketSDK();
        console.log('✅ poly-sdk 初始化成功（只读模式）\n');
        // 清除私钥，避免后续尝试使用交易功能
        config.sdk.privateKey = '';
      }
    } else {
      // 只读模式，无需认证
      sdk = new PolymarketSDK();
      console.log('✅ poly-sdk 初始化成功（只读模式）\n');
      console.log('💡 提示: 如需交易功能，请设置环境变量 POLYMARKET_PRIVATE_KEY 或在 config.js 中配置私钥\n');
    }

    // 创建钱包跟单实例
    follower = new WalletFollower(sdk, config);

    // 检查私钥和自动跟单配置
    const privateKeyForFollow = (config.sdk?.privateKey || process.env.POLYMARKET_PRIVATE_KEY || '').trim();
    const autoFollowEnabled = config.followSettings?.autoFollow === true;
    const hasWorkingPrivateKey = privateKeyForFollow && sdk && sdk.tradingService; // 检查是否有有效的交易服务
    
    console.log(`\n📋 配置检查:`);
    console.log(`   自动跟单: ${autoFollowEnabled ? '✅ 已启用' : '❌ 已禁用'}`);
    console.log(`   私钥状态: ${privateKeyForFollow ? `✅ 已配置 (${privateKeyForFollow.length} 字符)` : '❌ 未配置'}`);
    console.log(`   交易服务: ${hasWorkingPrivateKey ? '✅ 可用' : '❌ 不可用（使用只读模式）'}`);
    console.log(`   测试模式: ${config.followSettings?.dryRun !== false ? '✅ 是' : '❌ 否'}\n`);
    
    // 如果配置了自动跟单且有可用的交易服务，使用 SmartMoneyService 的自动跟单功能
    if (autoFollowEnabled && hasWorkingPrivateKey) {
      console.log('🎯 使用完整的自动跟单功能（SmartMoneyService）...\n');
      try {
        await follower.startAutoCopyTrading();
      } catch (error) {
        console.error('❌ 启动自动跟单失败:', error.message);
        console.log('🔄 回退到手动监听模式...\n');
        await follower.initialize();
        await follower.startWatching();
      }
    } else if (autoFollowEnabled && !hasWorkingPrivateKey) {
      // 自动跟单已启用但没有可用的交易服务，使用手动监听模式
      console.log('⚠️  自动跟单已启用，但交易服务不可用（可能是钱包未注册或网络问题）');
      console.log('💡 提示: 当前使用手动监听模式（仅查看，不执行交易）\n');
      await follower.initialize();
      await follower.startWatching();
    } else {
      // 使用传统的手动监听方式（仅查看）
      await follower.initialize();

      if (autoFollowEnabled) {
        console.log('\n🎯 自动跟单已启用，开始监听...\n');
        await follower.startWatching();
      } else {
        console.log('\nℹ️  自动跟单已禁用（仅在配置中设置 followSettings.autoFollow = true 时启用）');
        console.log('💡 提示: 当前仅展示钱包信息，不会执行实际交易\n');
      }
    }

    // 处理优雅退出
    process.on('SIGINT', async () => {
      console.log('\n\n⚠️  接收到退出信号...');
      if (follower) {
        await follower.stop();
      }
      if (sdk) {
        sdk.stop();
      }
      console.log('👋 再见！');
      process.exit(0);
    });

    process.on('SIGTERM', async () => {
      console.log('\n\n⚠️  接收到终止信号...');
      if (follower) {
        await follower.stop();
      }
      if (sdk) {
        sdk.stop();
      }
      console.log('👋 再见！');
      process.exit(0);
    });

    // 保持程序运行
    console.log('⏳ 程序运行中... (按 Ctrl+C 退出)');
    console.log('💡 提示: 按 Ctrl+C 停止程序时会显示盈利统计报告\n');
    
    // 添加统计查看命令（如果支持交互）
    if (process.stdin.isTTY) {
      process.stdin.setRawMode(true);
      process.stdin.resume();
      process.stdin.setEncoding('utf8');
      
      process.stdin.on('data', (key) => {
        // 按 's' 键显示统计
        if (key === 's' || key === 'S') {
          console.log('\n');
          if (follower && follower.profitTracker) {
            follower.displayProfitStats();
          }
          console.log('⏳ 程序运行中... (按 Ctrl+C 退出, 按 s 显示统计)\n');
        }
        // Ctrl+C
        if (key === '\u0003') {
          process.exit();
        }
      });
      
      console.log('💡 提示: 运行中按 "s" 键可以随时查看盈利统计\n');
    }
    
  } catch (error) {
    console.error('\n❌ 程序运行出错:', error);
    console.error(error.stack);
    if (sdk) {
      sdk.stop();
    }
    process.exit(1);
  }
}

// 运行主程序
main().catch(console.error);
