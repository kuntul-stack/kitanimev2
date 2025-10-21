const supabase = require('../config/supabase');
const bcrypt = require('bcrypt');

async function initializeDatabase() {
  try {
    const { count, error } = await supabase
      .from('admin_users')
      .select('*', { count: 'exact', head: true });

    if (error && error.code !== 'PGRST116') {
      throw error;
    }

    if (count === 0) {
      const hashedPassword = await bcrypt.hash('admin123', 10);
      await supabase
        .from('admin_users')
        .update({ password_hash: hashedPassword })
        .eq('username', 'admin');
    }

    console.log('Supabase database initialized successfully');
    return true;
  } catch (error) {
    console.error('Error initializing database:', error);
    throw error;
  }
}

const dbHelpers = {
  getActiveApiEndpoint: async () => {
    const { data, error } = await supabase
      .from('api_endpoints')
      .select('url')
      .eq('is_active', true)
      .maybeSingle();

    if (error) throw error;
    return data ? data.url : null;
  },

  getAllApiEndpoints: async () => {
    const { data, error } = await supabase
      .from('api_endpoints')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  updateApiEndpoint: async (id, url, isActive) => {
    if (isActive) {
      await supabase
        .from('api_endpoints')
        .update({ is_active: false })
        .neq('id', id);
    }

    const { error } = await supabase
      .from('api_endpoints')
      .update({
        url,
        is_active: isActive,
        updated_at: new Date().toISOString()
      })
      .eq('id', id);

    if (error) throw error;
    return true;
  },

  getAdSlotsByPosition: async (position) => {
    const { data, error } = await supabase
      .from('ad_slots')
      .select('*')
      .eq('position', position)
      .eq('is_active', true);

    if (error) throw error;
    return data || [];
  },

  getAllAdSlots: async () => {
    const { data, error } = await supabase
      .from('ad_slots')
      .select('*')
      .order('position')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  addAdSlot: async (name, position, type, content, isActive) => {
    const { data, error } = await supabase
      .from('ad_slots')
      .insert({
        name,
        position,
        type,
        content,
        is_active: isActive
      })
      .select()
      .single();

    if (error) throw error;
    return data.id;
  },

  updateAdSlot: async (id, name, position, type, content, isActive) => {
    const { error } = await supabase
      .from('ad_slots')
      .update({
        name,
        position,
        type,
        content,
        is_active: isActive,
        updated_at: new Date().toISOString()
      })
      .eq('id', id);

    if (error) throw error;
    return true;
  },

  deleteAdSlot: async (id) => {
    const { error } = await supabase
      .from('ad_slots')
      .delete()
      .eq('id', id);

    if (error) throw error;
    return true;
  },

  getAdminByUsername: async (username) => {
    const { data, error } = await supabase
      .from('admin_users')
      .select('*')
      .eq('username', username)
      .maybeSingle();

    if (error) throw error;
    return data;
  },

  getSetting: async (key) => {
    const { data, error } = await supabase
      .from('settings')
      .select('value')
      .eq('key', key)
      .maybeSingle();

    if (error) throw error;
    return data ? data.value : null;
  },

  updateSetting: async (key, value) => {
    const { error } = await supabase
      .from('settings')
      .update({
        value,
        updated_at: new Date().toISOString()
      })
      .eq('key', key);

    if (error) throw error;
    return true;
  }
};

module.exports = {
  supabase,
  initializeDatabase,
  ...dbHelpers
};
