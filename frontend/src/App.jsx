import React, { useCallback, useState, useEffect } from 'react';
import { LayoutDashboard, CheckCircle2, AlertOctagon, ListTodo, Plus, Search, Activity, Terminal, Server } from 'lucide-react';

export default function App() {
  const [items, setItems] = useState([]);
  const [title, setTitle] = useState('');
  const [type, setType] = useState('Task');
  const [search, setSearch] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  
  // Nginx proxies /api to the backend in both Docker Compose and Kubernetes.
  const apiUrl = import.meta.env.VITE_API_URL || '';

  const fetchItems = useCallback(async () => {
    const response = await fetch(`${apiUrl}/api/items`);
    if (!response.ok) throw new Error('Could not load items. Please try again.');
    const data = await response.json();
    setItems(Array.isArray(data) ? data : []);
  }, [apiUrl]);

  useEffect(() => {
    fetchItems()
      .catch(() => setError('Could not connect to TaskPulse. Please try again.'))
      .finally(() => setLoading(false));
  }, [fetchItems]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!title.trim() || submitting) return;
    setSubmitting(true);
    setError('');
    try {
      const response = await fetch(`${apiUrl}/api/items`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title: title.trim(), type })
      });
      if (!response.ok) throw new Error('Could not save the item. Please try again.');
      setTitle('');
      await fetchItems();
    } catch {
      setError('Could not save the item. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  const updateStatus = async (id, newStatus) => {
    setError('');
    try {
      const response = await fetch(`${apiUrl}/api/items/${id}/status`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus })
      });
      if (!response.ok) throw new Error('Could not update the item. Please try again.');
      await fetchItems();
    } catch {
      setError('Could not update the item. Please try again.');
    }
  };

  const visibleItems = items.filter((item) =>
    `${item.title} ${item.type} ${item.status}`.toLowerCase().includes(search.trim().toLowerCase())
  );

  const activeIncidents = items.filter(i => i.type === 'Incident' && i.status === 'Open').length;
  const openTasks = items.filter(i => i.type === 'Task' && i.status === 'Open').length;
  const resolvedTotal = items.filter(i => i.status === 'Resolved').length;

  return (
    <div className="flex h-screen bg-[#0B1120] text-slate-300 font-sans selection:bg-cyan-900 selection:text-cyan-50">
      
      {/* Sidebar navigation */}
      <aside className="w-72 bg-[#0F172A] border-r border-slate-800 flex flex-col shadow-2xl z-10">
        <div className="h-20 flex items-center px-8 border-b border-slate-800/50 bg-[#0B1120]/50">
          <Activity className="w-7 h-7 text-cyan-400 mr-3 animate-pulse" />
          <span className="text-2xl font-bold tracking-wider text-slate-100 uppercase">TaskPulse</span>
        </div>
        
        <div className="p-6">
          <p className="text-xs font-semibold text-slate-500 uppercase tracking-widest mb-4">Operations</p>
          <nav className="space-y-2">
            <a href="/" aria-current="page" className="flex items-center px-4 py-3 bg-cyan-950/40 text-cyan-400 border border-cyan-900/50 rounded-lg shadow-[0_0_15px_rgba(34,211,238,0.1)]">
              <LayoutDashboard className="w-5 h-5 mr-3" /> Dashboard
            </a>
            <button type="button" disabled aria-disabled="true" title="Not available yet" className="flex w-full items-center px-4 py-3 text-slate-600 cursor-not-allowed rounded-lg">
              <Server className="w-5 h-5 mr-3" /> Nodes &amp; Pods
            </button>
            <button type="button" disabled aria-disabled="true" title="Not available yet" className="flex w-full items-center px-4 py-3 text-slate-600 cursor-not-allowed rounded-lg">
              <Terminal className="w-5 h-5 mr-3" /> System Logs
            </button>
          </nav>
        </div>
      </aside>

      <main className="flex-1 flex flex-col overflow-hidden relative">
        {/* Top Header */}
        <header className="h-20 bg-[#0F172A]/80 backdrop-blur-md border-b border-slate-800 flex items-center justify-between px-10 sticky top-0 z-10">
          <h1 className="text-2xl font-semibold text-slate-100 tracking-tight">Infrastructure Overview</h1>
          <div className="flex items-center bg-[#0B1120] border border-slate-700/50 rounded-full px-4 py-2 shadow-inner focus-within:border-cyan-500/50 focus-within:ring-1 focus-within:ring-cyan-500/50 transition-all">
            <Search className="w-4 h-4 text-slate-500 mr-3" />
            <input
              type="text" 
              aria-label="Search resources"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search resources..." 
              className="bg-transparent border-none outline-none text-sm w-64 text-slate-200 placeholder-slate-600"
            />
          </div>
        </header>

        {/* Scrollable Content */}
        <div className="flex-1 overflow-y-auto p-10">
          
          {/* Metrics */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-10">
            <div className="bg-[#0F172A] p-6 rounded-2xl border border-slate-800 shadow-lg hover:border-slate-700 transition-colors group">
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-sm font-medium text-slate-400">Open Tasks</p>
                  <p className="text-4xl font-bold mt-2 text-slate-100">{openTasks}</p>
                </div>
                <div className="p-3 bg-blue-500/10 rounded-xl group-hover:bg-blue-500/20 transition-colors">
                  <ListTodo className="w-6 h-6 text-blue-400" />
                </div>
              </div>
            </div>

            <div className="bg-[#0F172A] p-6 rounded-2xl border border-slate-800 shadow-lg hover:border-rose-900/50 transition-colors group relative overflow-hidden">
              {activeIncidents > 0 && <div className="absolute top-0 left-0 w-full h-1 bg-rose-500"></div>}
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-sm font-medium text-slate-400">Active Incidents</p>
                  <p className="text-4xl font-bold mt-2 text-rose-400">{activeIncidents}</p>
                </div>
                <div className="p-3 bg-rose-500/10 rounded-xl group-hover:bg-rose-500/20 transition-colors">
                  <AlertOctagon className="w-6 h-6 text-rose-400" />
                </div>
              </div>
            </div>

            <div className="bg-[#0F172A] p-6 rounded-2xl border border-slate-800 shadow-lg hover:border-emerald-900/50 transition-colors group">
              <div className="flex justify-between items-start">
                <div>
                  <p className="text-sm font-medium text-slate-400">Resolved Items</p>
                  <p className="text-4xl font-bold mt-2 text-emerald-400">{resolvedTotal}</p>
                </div>
                <div className="p-3 bg-emerald-500/10 rounded-xl group-hover:bg-emerald-500/20 transition-colors">
                  <CheckCircle2 className="w-6 h-6 text-emerald-400" />
                </div>
              </div>
            </div>
          </div>

          {/* Action Form */}
          {error && <p role="alert" className="mb-6 rounded-lg border border-rose-900 bg-rose-950/40 px-4 py-3 text-rose-300">{error}</p>}
          <div className="bg-[#0F172A] p-8 rounded-2xl border border-slate-800 shadow-lg mb-10">
            <h3 className="text-lg font-semibold text-slate-200 mb-5 flex items-center">
              <Terminal className="w-5 h-5 mr-2 text-slate-400"/> Log System Event
            </h3>
            <form onSubmit={handleSubmit} className="flex flex-col md:flex-row gap-4">
              <input 
                type="text" 
                maxLength={255}
                aria-label="Describe the workload or failure"
                value={title} 
                onChange={(e) => setTitle(e.target.value)} 
                placeholder="Describe the workload or failure..." 
                className="flex-1 bg-[#0B1120] border border-slate-700/50 rounded-xl px-5 py-3 outline-none focus:border-cyan-500/50 focus:ring-1 focus:ring-cyan-500/50 text-slate-200 placeholder-slate-600 transition-all"
                required 
              />
              <select 
                value={type} 
                onChange={(e) => setType(e.target.value)} 
                className="bg-[#0B1120] border border-slate-700/50 rounded-xl px-5 py-3 outline-none focus:border-cyan-500/50 focus:ring-1 focus:ring-cyan-500/50 text-slate-300 transition-all min-w-[150px]"
              >
                <option value="Task">Task</option>
                <option value="Incident">Incident</option>
              </select>
              <button 
                type="submit" 
                disabled={submitting || !title.trim()}
                className="bg-cyan-600 hover:bg-cyan-500 disabled:opacity-50 disabled:cursor-not-allowed text-white px-8 py-3 rounded-xl flex items-center justify-center font-semibold shadow-lg shadow-cyan-900/20 transition-all duration-200 active:scale-95"
              >
                <Plus className="w-5 h-5 mr-2" /> {submitting ? 'Saving…' : 'Execute'}
              </button>
            </form>
          </div>

          {/* Operations Log */}
          <div className="bg-[#0F172A] rounded-2xl border border-slate-800 shadow-lg overflow-hidden">
            <div className="px-8 py-5 border-b border-slate-800 bg-[#0F172A]">
              <h3 className="text-lg font-semibold text-slate-200">Active Workloads</h3>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-[#0B1120]/50 text-xs uppercase tracking-wider text-slate-500">
                    <th className="px-8 py-4 font-semibold">Classification</th>
                    <th className="px-8 py-4 font-semibold">Description</th>
                    <th className="px-8 py-4 font-semibold">Status</th>
                    <th className="px-8 py-4 font-semibold text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/50">
                  {loading ? (
                    <tr><td colSpan="4" className="px-8 py-10 text-center text-slate-500">Loading items…</td></tr>
                  ) : visibleItems.length === 0 ? (
                    <tr><td colSpan="4" className="px-8 py-10 text-center text-slate-500">{search ? 'No matching items.' : 'No events logged yet.'}</td></tr>
                  ) : visibleItems.map((item) => (
                    <tr key={item.id} className="hover:bg-slate-800/20 transition-colors group">
                      <td className="px-8 py-5">
                        <span className={`inline-flex items-center px-2.5 py-1 rounded-md text-xs font-bold uppercase tracking-wider ${
                          item.type === 'Incident' ? 'bg-rose-500/10 text-rose-400 border border-rose-500/20' : 'bg-blue-500/10 text-blue-400 border border-blue-500/20'
                        }`}>
                          {item.type}
                        </span>
                      </td>
                      <td className="px-8 py-5 text-slate-300 font-medium">{item.title}</td>
                      <td className="px-8 py-5">
                        <div className="flex items-center">
                          {item.status === 'Resolved' ? (
                            <><span className="w-2 h-2 rounded-full bg-emerald-500 mr-2"></span><span className="text-sm text-emerald-400 font-medium">Resolved</span></>
                          ) : (
                            <><span className="w-2 h-2 rounded-full bg-amber-500 mr-2 animate-pulse"></span><span className="text-sm text-amber-400 font-medium">Investigating</span></>
                          )}
                        </div>
                      </td>
                      <td className="px-8 py-5 text-right">
                        {item.status !== 'Resolved' && (
                          <button 
                            onClick={() => updateStatus(item.id, 'Resolved')}
                            className="inline-flex items-center text-sm font-medium text-slate-400 hover:text-emerald-400 transition-colors opacity-0 group-hover:opacity-100 focus:opacity-100"
                          >
                            Mark Resolved <CheckCircle2 className="w-4 h-4 ml-1.5" />
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
          
        </div>
      </main>
    </div>
  );
}
