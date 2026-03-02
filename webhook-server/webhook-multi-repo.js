const http = require('http');
const { exec } = require('child_process');
const path = require('path');

const PORT = 9001;
const BASE_DIR = process.env.REPOS_BASE_DIR || `/home/${process.env.USER || require('os').userInfo().username}`; // Base directory for all repos

const server = http.createServer((req, res) => {
    if (req.method === 'POST' && req.url === '/deploy') {
        let body = '';
        
        req.on('data', chunk => {
            body += chunk.toString();
        });
        
        req.on('end', () => {
            try {
                const payload = JSON.parse(body);
                const repoName = payload.repository?.name || 'unknown';
                const branch = payload.ref || 'unknown';
                
                console.log(`Received webhook from repo: ${repoName}, branch: ${branch}`);
                
                // Only deploy main or master branch pushes
                if (branch === 'refs/heads/main' || branch === 'refs/heads/master') {
                    const repoPath = path.join(BASE_DIR, repoName);
                    const deployScript = path.join(repoPath, 'deploy.sh');
                    
                    console.log(`🚀 Triggering deployment for ${repoName}...`);
                    
                    // Send response immediately
                    res.writeHead(200, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ 
                        status: 'deployment_started',
                        repository: repoName,
                        path: repoPath
                    }));
                    
                    // Check if repo directory and deploy script exist
                    exec(`test -d "${repoPath}" && test -f "${deployScript}"`, (error) => {
                        if (error) {
                            console.error(`❌ Repository ${repoName} not found or no deploy.sh at ${repoPath}`);
                            return;
                        }
                        
                        // Run deployment in background
                        exec(`cd "${repoPath}" && ./deploy.sh`, (error, stdout, stderr) => {
                            if (error) {
                                console.error(`❌ Deployment failed for ${repoName}:`, stderr);
                            } else {
                                console.log(`✅ Deployment successful for ${repoName}!`);
                                console.log(stdout);
                            }
                        });
                    });
                } else {
                    console.log(`ℹ️ Ignoring push to ${branch} for ${repoName} (not main or master)`);
                    res.writeHead(200, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ 
                        status: 'ignored',
                        reason: 'not_main_branch',
                        branch: branch
                    }));
                }
            } catch (e) {
                console.error('❌ Error parsing webhook:', e);
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: 'Invalid JSON' }));
            }
        });
    } else {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Not found' }));
    }
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`🎣 Multi-repo webhook server running on port ${PORT}`);
    console.log(`🔗 Webhook URL: http://localhost:${PORT}/deploy`);
    console.log(`📁 Base directory: ${BASE_DIR}`);
    console.log(`📋 Will look for deploy.sh in each repo's root directory`);
});
