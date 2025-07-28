import React, { useState, useEffect } from 'react';
import { ThemeProvider, CssBaseline, Box, AppBar, Toolbar, Typography, Drawer, List, ListItem, ListItemText, ListItemButton, Divider, CircularProgress, Alert } from '@mui/material';
import SecurityIcon from '@mui/icons-material/Security';
import axios from 'axios';
import theme from './theme';
import ControlsPage from './pages/Controls';
import logo from './logo.png';

const drawerWidth = 240;

type Page = 'dashboard' | 'controls' | 'resources' | 'remediation';

// Define types for our dashboard data
interface DashboardMetrics {
  complianceScore: number | string;
  controlsNeedingAttention: number | string;
  totalFailingResources: number | string;
}

function App() {
  const [page, setPage] = useState<Page>('dashboard');
  const [dashboardMetrics, setDashboardMetrics] = useState<DashboardMetrics>({
    complianceScore: '#',
    controlsNeedingAttention: '#',
    totalFailingResources: '#'
  });
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch dashboard data from the backend
  useEffect(() => {
    if (page === 'dashboard') {
      fetchDashboardData();
    }
  }, [page]);

  const fetchDashboardData = async () => {
    setLoading(true);
    setError(null);
    
    try {
      // Fetch all config rules
      console.log('Fetching config rules...');
      const response = await axios.get('/api/config/rules');
      console.log('API response:', response.data);
      
      const { controls } = response.data;
      
      if (!controls || !Array.isArray(controls)) {
        throw new Error('Invalid API response format');
      }
      
      console.log(`Total controls: ${controls.length}`);
      
      // For each control, fetch its resources to see if it has any failing resources
      let controlsNeedingAttention = 0;
      const uniqueFailingResources = new Set<string>();
      
      const resourcePromises = controls.map((control: any) => {
        console.log(`Fetching resources for control: ${control.name}`);
        return axios.get(`/api/config/noncompliant/${control.name}`)
          .then(res => {
            const resources = res.data.resources || [];
            console.log(`Control ${control.name} has ${resources.length} failing resources`);
            
            // If this control has any resources, it needs attention
            if (resources.length > 0) {
              controlsNeedingAttention++;
            }
            
            // Add unique resource IDs to the set (deduplicates automatically)
            resources.forEach((resource: any) => {
              if (resource.resourceId) {
                uniqueFailingResources.add(resource.resourceId);
                console.log(`Added resource: ${resource.resourceId}`);
              }
            });
            
            return { controlName: control.name, resourceCount: resources.length, resources };
          })
          .catch(err => {
            console.error(`Error fetching resources for ${control.name}:`, err);
            return { controlName: control.name, resourceCount: 0, resources: [] };
          });
      });
      
      await Promise.all(resourcePromises);
      
      // Total unique failing resources
      const totalFailingResources = uniqueFailingResources.size;
      
      console.log(`Controls needing attention: ${controlsNeedingAttention}`);
      console.log(`Total unique failing resources: ${totalFailingResources}`);
      console.log(`Unique resource IDs:`, Array.from(uniqueFailingResources));
      
      // Calculate compliance score
      const compliantControls = controls.length - controlsNeedingAttention;
      const complianceScore = controls.length > 0 
        ? Math.round((compliantControls / controls.length) * 100) 
        : 0;
      
      // Update dashboard metrics
      setDashboardMetrics({
        complianceScore,
        controlsNeedingAttention,
        totalFailingResources
      });
      
    } catch (err: any) {
      console.error('Error fetching dashboard data:', err);
      setError(err.response?.data?.error || err.message || 'Failed to load dashboard data');
      
      // On error, show # as fallback
      setDashboardMetrics({
        complianceScore: '#',
        controlsNeedingAttention: '#',
        totalFailingResources: '#'
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Box sx={{ display: 'flex', height: '100vh', backgroundColor: 'background.default' }}>
        {/* Sidebar */}
        <Drawer
          variant="permanent"
          sx={{
            width: drawerWidth,
            flexShrink: 0,
            [`& .MuiDrawer-paper`]: {
              width: drawerWidth,
              boxSizing: 'border-box',
              backgroundColor: 'secondary.main',
              color: 'white',
            },
          }}
        >
          <Toolbar>
            <img 
              src={logo} 
              alt="Compliance Dashboard Logo" 
              style={{ 
                height: 96, 
                marginRight: 16,
                borderRadius: 4,
                objectFit: 'contain'
              }} 
            />
          </Toolbar>
          <Divider sx={{ bgcolor: 'divider', my: 1 }} />
          <List>
            <ListItem disablePadding>
              <ListItemButton selected={page === 'dashboard'} onClick={() => setPage('dashboard')}>
                <ListItemText primary="Dashboard" />
              </ListItemButton>
            </ListItem>
            <ListItem disablePadding>
              <ListItemButton selected={page === 'controls'} onClick={() => setPage('controls')}>
                <ListItemText primary="Controls" />
              </ListItemButton>
            </ListItem>
            <ListItem disablePadding>
              <ListItemButton selected={page === 'resources'} onClick={() => setPage('resources')}>
                <ListItemText primary="Resources" />
              </ListItemButton>
            </ListItem>
            <ListItem disablePadding>
              <ListItemButton selected={page === 'remediation'} onClick={() => setPage('remediation')}>
                <ListItemText primary="Remediation" />
              </ListItemButton>
            </ListItem>
          </List>
        </Drawer>

        {/* Main Content */}
        <Box 
          component="main"
          sx={{ 
            flexGrow: 1, 
            width: `calc(100% - ${drawerWidth}px)`,
            ml: `${drawerWidth}px`
          }}
        >
          <AppBar 
            position="fixed" 
            sx={{ 
              width: `calc(100% - ${drawerWidth}px)`, 
              ml: `${drawerWidth}px`, 
              backgroundColor: 'primary.main', 
              boxShadow: 0,
              zIndex: (theme) => theme.zIndex.drawer + 1 
            }}
          >
            <Toolbar>
              <Typography variant="h5" color="inherit" noWrap sx={{ fontWeight: 700 }}>
                Compliance Dashboard
              </Typography>
            </Toolbar>
          </AppBar>
          <Toolbar /> {/* This creates space for the fixed AppBar */}
          <Box sx={{ p: 4, overflow: 'auto' }}>
            {/* Conditional page rendering */}
            {page === 'dashboard' && (
              <>
                <Typography variant="h4" gutterBottom>
                  Welcome to your NIST-800 Compliance Dashboard
                </Typography>
                <Typography variant="body1" sx={{ mb: 4, color: 'text.secondary' }}>
                  Visualize, track, and remediate your AWS compliance posture with real-time controls, resource mapping, and actionable remediation guidance.
                </Typography>
                
                {error && (
                  <Alert severity="error" sx={{ mb: 3 }}>
                    {error}
                  </Alert>
                )}
                
                {loading ? (
                  <Box sx={{ display: 'flex', justifyContent: 'center', my: 4 }}>
                    <CircularProgress />
                  </Box>
                ) : (
                  <Box sx={{ display: 'flex', gap: 3, flexWrap: 'wrap' }}>
                    {/* Compliance Score Card */}
                    <Box sx={{ bgcolor: 'background.paper', p: 3, borderRadius: 3, minWidth: 320, boxShadow: 1 }}>
                      <Typography variant="h6" color="primary" gutterBottom>
                        Compliance Score
                      </Typography>
                      <Typography 
                        variant="h2" 
                        color={typeof dashboardMetrics.complianceScore === 'number' && dashboardMetrics.complianceScore > 50 ? 'success.main' : 'error.main'} 
                        fontWeight={700}
                      >
                        {typeof dashboardMetrics.complianceScore === 'number' ? `${dashboardMetrics.complianceScore}%` : dashboardMetrics.complianceScore}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">Compliant Controls</Typography>
                    </Box>
                    
                    {/* Controls Needing Attention Card */}
                    <Box sx={{ bgcolor: 'background.paper', p: 3, borderRadius: 3, minWidth: 320, boxShadow: 1 }}>
                      <Typography variant="h6" color="primary" gutterBottom>
                        Controls Needing Attention
                      </Typography>
                      <Typography 
                        variant="h2" 
                        color={typeof dashboardMetrics.controlsNeedingAttention === 'number' && dashboardMetrics.controlsNeedingAttention > 0 ? 'warning.main' : 'success.main'} 
                        fontWeight={700}
                      >
                        {dashboardMetrics.controlsNeedingAttention}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">Pending Remediation</Typography>
                    </Box>
                    
                    {/* Failing Resources Card */}
                    <Box sx={{ bgcolor: 'background.paper', p: 3, borderRadius: 3, minWidth: 320, boxShadow: 1 }}>
                      <Typography variant="h6" color="primary" gutterBottom>
                        Total Failing Resources
                      </Typography>
                      <Typography 
                        variant="h2" 
                        color={typeof dashboardMetrics.totalFailingResources === 'number' && dashboardMetrics.totalFailingResources > 0 ? 'error.main' : 'success.main'} 
                        fontWeight={700}
                      >
                        {dashboardMetrics.totalFailingResources}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">Resources Non-compliant</Typography>
                    </Box>
                  </Box>
                )}
              </>
            )}
            {page === 'controls' && <ControlsPage />}
            {page === 'resources' && (
              <Typography variant="h4">Resources (Coming Soon)</Typography>
            )}
            {page === 'remediation' && (
              <Typography variant="h4">Remediation (Coming Soon)</Typography>
            )}
          </Box>
        </Box>
      </Box>
    </ThemeProvider>
  );
}

export default App;
